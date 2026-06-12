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
  System.SysUtils, Uni;

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
// URL completa de cotejo para el QR tributario del ticket / factura
function ConstruirUrlQR(const ANif, ASerie, ANumero: string;
                        AFecha: TDateTime;
                        AImporteTotal: Currency): string;
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
  System.Classes, System.Hash,
  inLibGlobalVar, inLibAppParam;

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
    '?nif='      + CodificarParametroURL(Trim(ANif)) +
    '&numserie=' + CodificarParametroURL(
                     ComponerNumSerieFactura(ASerie, ANumero)) +
    '&fecha='    + CodificarParametroURL(
                     FormatDateTime('dd-mm-yyyy', AFecha)) +
    '&importe='  + CodificarParametroURL(
                     FormatearImporteVerifactu(AImporteTotal));
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
