{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactu                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Núcleo del subsistema Verifactu (AEAT). Construcción de la URL de         }
{    cotejo del QR tributario (Orden HAC/1177/2024), helpers de formato y      }
{    registro de eventos encadenados por hash en fza_verifactu_eventos.        }
{******************************************************************************}
unit inLibVerifactu;

interface

uses
  System.SysUtils, Uni, frxClass,  Data.DB;

const
  // URLs oficiales del servicio de cotejo del QR tributario. Se pueden
  // sobreescribir con appVerifactuUrlQRPre / appVerifactuUrlQRPro.
  cVerifactuUrlQRPre =
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR';
  cVerifactuUrlQRPro =
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR';
  // Tipos de evento para TIPO_EVENTO_LOG de fza_verifactu_eventos.
  // Pendiente de unificar con el catálogo de tipos de OdaVeriFactu.
  cEventoVerifactuInfo       = 1;
  cEventoVerifactuEncolado   = 2;
  cEventoVerifactuEnvioOk    = 3;
  cEventoVerifactuEnvioError = 4;

// True si el parámetro appVerifactuActivo está marcado
function VerifactuActivo: Boolean;
// 'PRE' (pruebas) o 'PRO' (producción) según appVerifactuEntorno
function VerifactuEntorno: string;
// Identificador serie+número que se comunica a la AEAT. DEBE coincidir
// con el NumSerieFactura del registro de facturación que se envíe.
function ComponerNumSerieFactura(const ASerie, ANumero: string): string;
// Importe con 2 decimales y punto como separador (formato QR y registro)
function FormatearImporteVerifactu(AImporte: Currency): string;
// NIF normalizado para Verifactu: solo letras y dígitos, en mayúsculas.
// El MISMO valor debe viajar en el QR y en el registro de facturación.
function NormalizarNifVerifactu(const AValor: string): string;
// URL completa de cotejo para el QR tributario del ticket / factura
function ConstruirUrlQR(const ANif, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
// PNG del QR tributario (DelphiZXIngQRCode, corrección M) como bytes.
// Sin canvas ni handles GDI compartidos: usable desde el hilo de envío.
function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
// FastReport: rellena el TfrxPictureView llamado 'qrverifactu' con el
// QR tributario de la factura del registro activo de su banda (campos
// NIF_EMPRESA_FAC, SERIE_FAC, NUMERO_FAC, FECHA_FAC,
// TOTAL_LIQUIDO_FAC). Encadenar desde TfrxReport.OnBeforePrint.
procedure SustituirQRVerifactuEnReport(Component: TfrxReportComponent);
// FastReport: si el formato cargado no trae un TfrxPictureView llamado
// 'qrverifactu', lo crea (30 mm, arriba a la derecha) dentro de la
// cabecera de página; los objetos sueltos en la página no reciben
// OnBeforePrint y el hueco quedaba sin rellenar. Si el diseñador ya lo
// colocó, se respeta su posición.
procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
// FastReport: ajusta el memo de título de los formatos de factura
// ('FACTURA') al tipo del registro activo: FACTURA SIMPLIFICADA /
// FACTURA RECTIFICATIVA / FACTURA. Encadenar desde OnBeforePrint.
// Requiere que el dataset de cabecera lleve TIPO_FAC.
procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
// FastReport: vía fiable. En esta versión el OnBeforePrint NO llega a
// los objetos sueltos de las bandas estáticas (cabecera/pie/título de
// página), solo a las bandas y a los objetos de bandas de datos. El QR
// y el título 'FACTURA' viven en la cabecera de página, así que cuando
// se dispara una banda recorremos sus hijos y rellenamos el QR y el
// título con el registro de factura activo. Encadenar desde
// OnBeforePrint además de las dos anteriores.
procedure AplicarVerifactuEnBanda(Component: TfrxReportComponent);
// FastReport: rellena directamente (sin esperar a OnBeforePrint) el QR
// y el título de TODO el informe con el registro de ADataSet. Para una
// sola factura, llamar tras cargar el formato y antes de PrepareReport:
// el QR sale por defecto aunque el hueco quede suelto en la página.
procedure AplicarVerifactuEnReportDirecto(AReport: TfrxReport;
                                          ADataSet: TDataSet);
// Registra un evento en fza_verifactu_eventos manteniendo la cadena de
// hashes (HASH_ANTERIOR -> HASH_PROPIO). AConn puede ser la conexión
// global o la propia del hilo de la cola.
procedure RegistrarEventoVerifactu(AConn: TUniConnection;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string = '';
                                   const ASerieFac: string = '';
                                   const ANumeroFac: string = '');

implementation

uses
  System.Classes, System.Hash, Vcl.Imaging.pngimage,
  DelphiZXIngQRCode, frxDBSet,
  inLibGlobalVar, inLibAppParam, inLibFotos;

// True si el dataset tiene los campos de cabecera de factura que
// necesitan el QR y el título (vi_facturas / vi_facturas_print)
function TieneCamposFactura(ADataSet: TDataSet): Boolean;
begin
  Result := (ADataSet <> nil) and
            (ADataSet.FindField('NIF_EMPRESA_FAC') <> nil) and
            (ADataSet.FindField('SERIE_FAC') <> nil) and
            (ADataSet.FindField('NUMERO_FAC') <> nil) and
            (ADataSet.FindField('FECHA_FAC') <> nil) and
            (ADataSet.FindField('TOTAL_LIQUIDO_FAC') <> nil);
end;

// Dataset de cabecera de factura para un objeto del report: primero la
// banda padre; si el objeto cuelga de una banda sin datos (cabecera de
// página) o de la propia página, se busca entre los datasets del
// report el que tenga los campos de factura.
function DataSetFacturaDeReport(AObj: TfrxComponent): TDataSet;
var
  oReport: TfrxReport;
  oDs:     TDataSet;
  i:       Integer;
begin
  Result := ObtenerDataSetDeBandaPadre(AObj);
  if not TieneCamposFactura(Result) then
  begin
    Result := nil;
    oReport := AObj.Report;
    if oReport <> nil then
    begin
      for i := 0 to oReport.Datasets.Count - 1 do
      begin
        if (Result = nil) and
           (oReport.Datasets[i].DataSet is TfrxDBDataset) then
        begin
          oDs := TfrxDBDataset(oReport.Datasets[i].DataSet).DataSet;
          if TieneCamposFactura(oDs) then
            Result := oDs;
        end;
      end;
    end;
  end;
end;

function VerifactuActivo: Boolean;
begin
  Result := oAppParams.GetBool('appVerifactuActivo', False);
end;

function VerifactuEntorno: string;
begin
  Result := UpperCase(Trim(oAppParams.GetString('appVerifactuEntorno',
                                                'PRE')));
  if Result <> 'PRO' then
    Result := 'PRE';
end;

function ComponerNumSerieFactura(const ASerie, ANumero: string): string;
begin
  // Concatenación simple serie+número. Si OdaVeriFactu compone distinto
  // el identificador, ajustar SOLO aquí: el QR y el registro enviado a
  // la AEAT deben llevar exactamente el mismo valor.
  Result := Trim(ASerie) + Trim(ANumero);
end;

function FormatearImporteVerifactu(AImporte: Currency): string;
var
  oFmt: TFormatSettings;
begin
  oFmt := TFormatSettings.Create;
  oFmt.DecimalSeparator  := '.';
  oFmt.ThousandSeparator := #0;
  Result := FormatFloat('0.00', AImporte, oFmt);
end;

function NormalizarNifVerifactu(const AValor: string): string;
var
  cActual: Char;
begin
  Result := '';
  for cActual in UpperCase(Trim(AValor)) do
  begin
    if ((cActual >= 'A') and (cActual <= 'Z')) or
       ((cActual >= '0') and (cActual <= '9')) then
      Result := Result + cActual;
  end;
end;

// Percent-encode de un valor de parámetro de URL (RFC 3986): solo quedan
// sin codificar los caracteres no reservados.
function CodificarParametroURL(const AValor: string): string;
var
  aBytes:   TBytes;
  iOcteto:  Byte;
  oSalida:  TStringBuilder;
begin
  oSalida := TStringBuilder.Create;
  try
    aBytes := TEncoding.UTF8.GetBytes(AValor);
    for iOcteto in aBytes do
    begin
      if ((iOcteto >= Ord('A')) and (iOcteto <= Ord('Z'))) or
         ((iOcteto >= Ord('a')) and (iOcteto <= Ord('z'))) or
         ((iOcteto >= Ord('0')) and (iOcteto <= Ord('9'))) or
         (iOcteto = Ord('-')) or (iOcteto = Ord('.')) or
         (iOcteto = Ord('_')) or (iOcteto = Ord('~')) then
        oSalida.Append(Char(iOcteto))
      else
        oSalida.Append('%' + IntToHex(iOcteto, 2));
    end;
    Result := oSalida.ToString;
  finally
    FreeAndNil(oSalida);
  end;
end;

function ConstruirUrlQR(const ANif, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
var
  sBase: string;
begin
  if VerifactuEntorno = 'PRO' then
    sBase := oAppParams.GetString('appVerifactuUrlQRPro', cVerifactuUrlQRPro)
  else
    sBase := oAppParams.GetString('appVerifactuUrlQRPre', cVerifactuUrlQRPre);
  // Formato fijado por la AEAT (documento técnico del QR tributario):
  // nif, numserie, fecha dd-mm-aaaa e importe total con punto decimal
  Result := sBase +
    '?nif='      + CodificarParametroURL(NormalizarNifVerifactu(ANif)) +
    '&numserie=' + CodificarParametroURL(
                     ComponerNumSerieFactura(ASerie, ANumero)) +
    '&fecha='    + CodificarParametroURL(
                     FormatDateTime('dd-mm-yyyy', AFecha)) +
    '&importe='  + CodificarParametroURL(
                     FormatearImporteVerifactu(AImporteTotal));
end;

function GenerarQRPngVerifactu(const AUrl: string;
                               AEscala: Integer = 4): TBytes;
var
  oQR:     TDelphiZXIngQRCode;
  oPng:    TPngImage;
  oStream: TMemoryStream;
  iX:      Integer;
  iY:      Integer;
  pLinea:  PByteArray;
begin
  SetLength(Result, 0);
  if (Trim(AUrl) <> '') and (AEscala >= 1) then
  begin
    oQR     := TDelphiZXIngQRCode.Create;
    oPng    := nil;
    oStream := nil;
    try
      // DelphiZXIngQRCode genera en nivel L (fijo en la librería). El
      // QR del ticket impreso sí va en nivel M: lo genera la propia
      // impresora con el comando nativo ESC/POS (ImprimirQRNativo, 49).
      oQR.Data      := AUrl;
      oQR.Encoding  := qrUTF8NoBOM;
      oQR.QuietZone := 4;
      oPng := TPngImage.CreateBlank(COLOR_GRAYSCALE, 8,
                                    oQR.Columns * AEscala,
                                    oQR.Rows * AEscala);
      for iY := 0 to oPng.Height - 1 do
      begin
        pLinea := oPng.Scanline[iY];
        for iX := 0 to oPng.Width - 1 do
        begin
          if oQR.IsBlack[iY div AEscala, iX div AEscala] then
            pLinea[iX] := 0
          else
            pLinea[iX] := 255;
        end;
      end;
      oStream := TMemoryStream.Create;
      oPng.SaveToStream(oStream);
      SetLength(Result, oStream.Size);
      if oStream.Size > 0 then
        Move(oStream.Memory^, Result[0], oStream.Size);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
      FreeAndNil(oQR);
    end;
  end;
end;

// Rellena un TfrxPictureView con el QR tributario de la factura del
// dataset dado (vacío si Verifactu inactivo o sin datos)
procedure RellenarQRPicture(APic: TfrxPictureView; ADataSet: TDataSet);
var
  aPng:    TBytes;
  oPng:    TPngImage;
  oStream: TBytesStream;
  sUrl:    string;
begin
  sUrl := '';
  if VerifactuActivo and TieneCamposFactura(ADataSet) and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') then
    sUrl := ConstruirUrlQR(
              ADataSet.FieldByName('NIF_EMPRESA_FAC').AsString,
              ADataSet.FieldByName('SERIE_FAC').AsString,
              ADataSet.FieldByName('NUMERO_FAC').AsString,
              ADataSet.FieldByName('FECHA_FAC').AsDateTime,
              ADataSet.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency);
  if sUrl = '' then
    APic.Picture.Assign(nil)
  else
  begin
    aPng := GenerarQRPngVerifactu(sUrl);
    oPng := TPngImage.Create;
    oStream := TBytesStream.Create(aPng);
    try
      oPng.LoadFromStream(oStream);
      APic.Picture.Assign(oPng);
    finally
      FreeAndNil(oStream);
      FreeAndNil(oPng);
    end;
  end;
end;

// Ajusta el memo de título 'FACTURA' al tipo del dataset (SIMPLIFICADA
// / RECTIFICATIVA / normal). Solo actúa sobre el memo de título.
procedure AjustarTituloMemo(AMemo: TfrxMemoView; ADataSet: TDataSet);
var
  sTexto: string;
  sTipo:  string;
begin
  sTexto := UpperCase(Trim(AMemo.Text));
  if ((sTexto = 'FACTURA') or
      (sTexto = 'FACTURA SIMPLIFICADA') or
      (sTexto = 'FACTURA RECTIFICATIVA')) and
     (ADataSet <> nil) and
     (ADataSet.FindField('TIPO_FAC') <> nil) then
  begin
    sTipo := UpperCase(Trim(ADataSet.FieldByName('TIPO_FAC').AsString));
    if sTipo = 'SIMPLIFICADA' then
      AMemo.Text := 'FACTURA SIMPLIFICADA'
    else if sTipo = 'RECTIFICATIVA' then
      AMemo.Text := 'FACTURA RECTIFICATIVA'
    else
      AMemo.Text := 'FACTURA';
  end;
end;

procedure SustituirQRVerifactuEnReport(Component: TfrxReportComponent);
begin
  if (Component is TfrxPictureView) and
     SameText(Component.Name, 'qrverifactu') then
    RellenarQRPicture(TfrxPictureView(Component),
                      DataSetFacturaDeReport(Component));
end;

procedure AsegurarQRVerifactuEnReport(AReport: TfrxReport);
var
  i, j:   Integer;
  oPage:  TfrxReportPage;
  oBanda: TfrxBand;
  oPic:   TfrxPictureView;
  dLado:  Extended;
  dBase:  Extended;
begin
  if (AReport <> nil) and (AReport.FindObject('qrverifactu') = nil) then
  begin
    // Primera página de informe (Pages[0] suele ser la de datos)
    oPage := nil;
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if (oPage = nil) and (AReport.Pages[i] is TfrxReportPage) then
        oPage := TfrxReportPage(AReport.Pages[i]);
    end;
    if oPage <> nil then
    begin
      // El QR tiene que vivir DENTRO de una banda: los objetos
      // sueltos en la página no pasan por OnBeforePrint y el hueco
      // se quedaba vacío. Preferimos la cabecera de página (sale en
      // todas las hojas con el registro activo); si el formato no
      // tiene, el título de informe.
      oBanda := nil;
      for j := 0 to oPage.Objects.Count - 1 do
      begin
        if (oBanda = nil) and
           (TObject(oPage.Objects[j]) is TfrxPageHeader) then
          oBanda := TfrxBand(oPage.Objects[j]);
      end;
      if oBanda = nil then
      begin
        for j := 0 to oPage.Objects.Count - 1 do
        begin
          if (oBanda = nil) and
             (TObject(oPage.Objects[j]) is TfrxReportTitle) then
            oBanda := TfrxBand(oPage.Objects[j]);
        end;
      end;
      // Último recurso: una banda de datos (siempre dispara
      // OnBeforePrint). Nunca dejamos el QR suelto en la página.
      if oBanda = nil then
      begin
        for j := 0 to oPage.Objects.Count - 1 do
        begin
          if (oBanda = nil) and
             (TObject(oPage.Objects[j]) is TfrxDataBand) then
            oBanda := TfrxBand(oPage.Objects[j]);
        end;
      end;
      // 30 mm (mínimo AEAT 30x30) pegado al margen superior derecho.
      // El usuario puede recolocarlo en el diseñador: al guardar el
      // formato con el objeto, esta inyección deja de actuar.
      // fr01cm = 1 mm en píxeles del informe.
      dLado := 30 * fr01cm;
      if oBanda <> nil then
      begin
        oPic := TfrxPictureView.Create(oBanda);
        dBase := oBanda.Width;
        if dBase <= 0 then
          dBase := oPage.Width;
        // La banda debe poder contener el QR sin pisar lo de debajo
        if oBanda.Height < dLado then
          oBanda.Height := dLado;
      end
      else
      begin
        oPic := TfrxPictureView.Create(oPage);
        dBase := oPage.Width;
      end;
      oPic.Name    := 'qrverifactu';
      oPic.SetBounds(dBase - dLado, 0, dLado, dLado);
      oPic.Center  := True;
      oPic.KeepAspectRatio := True;
    end;
  end;
end;

procedure SustituirTituloFacturaEnReport(Component: TfrxReportComponent);
begin
  if Component is TfrxMemoView then
    AjustarTituloMemo(TfrxMemoView(Component),
                      DataSetFacturaDeReport(Component));
end;

// Recorre recursivamente los hijos de una banda aplicando el QR y el
// título a los que correspondan, con el registro de factura activo
procedure AplicarVerifactuARama(AComp: TfrxComponent; ADataSet: TDataSet);
var
  i: Integer;
begin
  if AComp <> nil then
  begin
    if (AComp is TfrxPictureView) and
       SameText(AComp.Name, 'qrverifactu') then
      RellenarQRPicture(TfrxPictureView(AComp), ADataSet);
    if AComp is TfrxMemoView then
      AjustarTituloMemo(TfrxMemoView(AComp), ADataSet);
    for i := 0 to AComp.Objects.Count - 1 do
      AplicarVerifactuARama(TfrxComponent(AComp.Objects[i]), ADataSet);
  end;
end;

procedure AplicarVerifactuEnBanda(Component: TfrxReportComponent);
var
  oDataSet: TDataSet;
begin
  if Component is TfrxBand then
  begin
    oDataSet := DataSetFacturaDeReport(Component);
    if TieneCamposFactura(oDataSet) then
      AplicarVerifactuARama(Component, oDataSet);
  end;
end;

procedure AplicarVerifactuEnReportDirecto(AReport: TfrxReport;
                                          ADataSet: TDataSet);
var
  i: Integer;
begin
  // Relleno directo, sin esperar a OnBeforePrint: recorre TODO el árbol
  // de cada página y rellena el QR y el título con ADataSet. Para una
  // sola factura (vista previa / impresión / PDF de un documento) el QR
  // sale por defecto aunque el hueco quede suelto en la página y su
  // objeto no reciba el evento.
  if (AReport <> nil) and TieneCamposFactura(ADataSet) then
  begin
    for i := 0 to AReport.PagesCount - 1 do
    begin
      if AReport.Pages[i] is TfrxReportPage then
        AplicarVerifactuARama(TfrxReportPage(AReport.Pages[i]), ADataSet);
    end;
  end;
end;

procedure RegistrarEventoVerifactu(AConn: TUniConnection;
                                   ATipoEvento: Integer;
                                   const ADescripcion: string;
                                   const ADatosAdicionales: string;
                                   const ASerieFac: string;
                                   const ANumeroFac: string);
var
  Qry: TUniQuery;
  sHashAnterior: string;
  sHashPropio:   string;
  sFirma:        string;
  sInstante:     string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    // Último eslabón de la cadena de hashes
    Qry.SQL.Text := ' SELECT HASH_PROPIO_LOG ' +
                    ' FROM fza_verifactu_eventos ' +
                    ' ORDER BY ID_LOG DESC ' +
                    ' LIMIT 1';
    Qry.Open;
    if Qry.IsEmpty then
      sHashAnterior := StringOfChar('0', 64)
    else
      sHashAnterior := Qry.Fields[0].AsString;
    Qry.Close;
    sInstante   := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now);
    sHashPropio := THashSHA2.GetHashString(
      sInstante + '|' + IntToStr(ATipoEvento) + '|' + oUser + '|' +
      ADescripcion + '|' + ADatosAdicionales + '|' + sHashAnterior);
    // Firma provisional (hash del hash + versión del programa); unificar
    // cuando se incorporen las librerías de firma de OdaVeriFactu
    sFirma := THashSHA2.GetHashString(sHashPropio + '|' + oVersion);
    Qry.SQL.Text :=
      ' INSERT INTO fza_verifactu_eventos ' +
      ' (TIMESTAMP_LOG, TIPO_EVENTO_LOG, USUARIO_LOG, VERSION_LOG, ' +
      '  DESCRIPCION_LOG, DATOS_ADICIONALES_LOG, HASH_ANTERIOR_LOG, ' +
      '  HASH_PROPIO_LOG, FIRMA_DIGITAL_LOG, NUMERO_FAC_LOG, ' +
      '  SERIE_FAC_LOG) ' +
      ' VALUES ' +
      ' (:INSTANTE, :TIPO, :USUARIO, :VERSION, :DESCRIPCION, ' +
      '  NULLIF(:DATOS, ''''), :HASHANT, :HASHPROPIO, :FIRMA, ' +
      '  NULLIF(:NUMERO, ''''), NULLIF(:SERIE, ''''))';
    Qry.ParamByName('INSTANTE').AsString    := sInstante;
    Qry.ParamByName('TIPO').AsInteger       := ATipoEvento;
    Qry.ParamByName('USUARIO').AsString     := oUser;
    Qry.ParamByName('VERSION').AsString     := oVersion;
    Qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    Qry.ParamByName('DATOS').AsString       := ADatosAdicionales;
    Qry.ParamByName('HASHANT').AsString     := sHashAnterior;
    Qry.ParamByName('HASHPROPIO').AsString  := sHashPropio;
    Qry.ParamByName('FIRMA').AsString       := sFirma;
    Qry.ParamByName('NUMERO').AsString      := ANumeroFac;
    Qry.ParamByName('SERIE').AsString       := ASerieFac;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

end.
