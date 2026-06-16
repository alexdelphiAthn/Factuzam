{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalVerifactuDecl                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Declaración responsable del sistema informático de facturación            }
{    (art. 13 del RD 1007/2023). Muestra el texto con los datos del SIF        }
{    (nombre, versión, productor e instalación) en un memo de solo lectura.    }
{******************************************************************************}
unit inMtoModalVerifactuDecl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMemo, cxButtons,
  inMtoFrmBase;

type
  TfrmModalVerifactuDecl = class(TfrmBase)
    mDeclaracion: TcxMemo;
    pnlButton: TPanel;
    btnAceptar: TcxButton;
  private
    procedure CargarTexto;
  public
    class procedure Ejecutar(AOwner: TComponent);
  end;

implementation

uses
  inLibGlobalVar, inLibAppParam, inLibVerifactu;

{$R *.dfm}

function ValorDeclaracion(const AValor, APendiente: string): string;
begin
  if Trim(AValor) <> '' then
    Result := Trim(AValor)
  else
    Result := APendiente;
end;

function ConstruirTextoDeclaracion(const AProductor,
                                   ANif,
                                   ADireccion,
                                   ALugar,
                                   AFecha,
                                   AInstalacion: string;
                                   AModo: TModoVerifactu): string;
var
  sModalidad: string;
  sApartadoD: string;
  sApartadoE: string;
  sApartadoG: string;
  sInfoModalidad: string;
  sQr: string;
begin
  case AModo of
    mvNoVerifactu:
    begin
      sModalidad := 'NO VERI*FACTU';
      sApartadoD :=
        'Factuzam es un sistema informático de facturación desarrollado en ' +
        'Delphi VCL para equipos Windows, con base de datos MariaDB y acceso ' +
        'a datos mediante UniDAC. Puede trabajar en instalaciones locales o ' +
        'en red, con una o varias empresas configuradas como obligados ' +
        'tributarios diferenciados. Permite emitir facturas completas y ' +
        'facturas simplificadas, conservar sus registros de facturación, ' +
        'generar la huella o hash encadenada, registrar eventos relevantes, ' +
        'gestionar altas, anulaciones, rectificaciones y subsanaciones, ' +
        'firmar electrónicamente los registros y eventos fiscales y preparar ' +
        'su exportación o conservación en modalidad NO VERI*FACTU.';
      sApartadoE :=
        'No. La modalidad declarada es NO VERI*FACTU. En esta modalidad el ' +
        'sistema no realiza la remisión automática y continuada de los ' +
        'registros de facturación a la AEAT, sino que genera, encadena, ' +
        'firma, conserva y permite exportar los registros de facturación y ' +
        'los registros de evento exigibles.';
      sApartadoG :=
        'En modalidad NO VERI*FACTU se utiliza firma electrónica XAdES ' +
        'enveloped con certificado electrónico de la empresa emisora ' +
        'seleccionado en la ficha de empresa y disponible en el almacén ' +
        'personal de certificados de Windows. La firma se realiza con ' +
        'algoritmos SHA-256/RSA y conserva los datos identificativos del ' +
        'certificado firmante, incluyendo serie, titular y huella.';
      sInfoModalidad :=
        'Modalidad NO VERI*FACTU: los registros de facturación se generan ' +
        'en el sistema, se encadenan mediante huella, se firman con el ' +
        'certificado configurado y quedan conservados para consulta, ' +
        'exportación y puesta a disposición cuando proceda. La ausencia de ' +
        'remisión automática no elimina la obligación de conservar los ' +
        'registros íntegros, trazables, accesibles y legibles.';
      sQr :=
        'Código QR tributario: las facturas emitidas en esta modalidad ' +
        'mantienen los datos necesarios de identificación y cotejo conforme ' +
        'al diseño fiscal aplicable, sin que exista remisión automática ' +
        'continuada a la AEAT.';
    end;
    else
    begin
      sModalidad := 'VERI*FACTU';
      sApartadoD :=
        'Factuzam es un sistema informático de facturación desarrollado en ' +
        'Delphi VCL para equipos Windows, con base de datos MariaDB y acceso ' +
        'a datos mediante UniDAC. Puede trabajar en instalaciones locales o ' +
        'en red, con una o varias empresas configuradas como obligados ' +
        'tributarios diferenciados. Permite emitir facturas completas y ' +
        'facturas simplificadas, conservar sus registros de facturación, ' +
        'generar la huella o hash encadenada, registrar eventos relevantes, ' +
        'gestionar altas, anulaciones, rectificaciones y subsanaciones, ' +
        'generar el código QR tributario y remitir los registros de ' +
        'facturación a la AEAT en modalidad VERI*FACTU.';
      sApartadoE :=
        'No como producto único, porque Factuzam también contempla una ' +
        'modalidad NO VERI*FACTU. La modalidad declarada en este texto es ' +
        'VERI*FACTU: el sistema trabaja como sistema de emisión de facturas ' +
        'verificables, con remisión continuada, segura, correcta, íntegra, ' +
        'automática, consecutiva, instantánea y fehaciente de los registros ' +
        'de facturación generados.';
      sApartadoG :=
        'No procede para la modalidad VERI*FACTU declarada. La comunicación ' +
        'con la AEAT se realiza mediante los mecanismos de identificación y ' +
        'autenticación exigidos para la remisión de registros. Si se activa ' +
        'la modalidad NO VERI*FACTU, el sistema firma electrónicamente los ' +
        'registros mediante XAdES con certificado de empresa.';
      sInfoModalidad :=
        'Modalidad VERI*FACTU: los registros de facturación se generan y se ' +
        'remiten electrónicamente a la AEAT desde la cola de envíos. El ' +
        'sistema conserva el estado de cada envío, la respuesta recibida y ' +
        'la información de trazabilidad necesaria para revisar incidencias.';
      sQr :=
        'Código QR tributario: las facturas emitidas en modalidad ' +
        'VERI*FACTU incluyen el código QR de cotejo exigido para su ' +
        'verificación.';
    end;
  end;
  Result :=
    'DECLARACIÓN RESPONSABLE DEL SISTEMA INFORMÁTICO DE FACTURACIÓN' +
    sLineBreak +
    'Modalidad declarada: ' + sModalidad +
    sLineBreak + sLineBreak +
    'De conformidad con el artículo 15 de la Orden HAC/1177/2024, ' +
    'de 17 de octubre, por la que se desarrollan las especificaciones ' +
    'técnicas, funcionales y de contenido referidas en el Reglamento ' +
    'aprobado por el Real Decreto 1007/2023, de 5 de diciembre, y en el ' +
    'Reglamento por el que se regulan las obligaciones de facturación, ' +
    'aprobado por Real Decreto 1619/2012, de 30 de noviembre, se hace ' +
    'constar la siguiente declaración responsable.' +
    sLineBreak + sLineBreak +
    'A - Nombre del sistema informático: Factuzam' + sLineBreak +
    'B - Código identificador del sistema informático: FZ' + sLineBreak +
    'C - Identificador completo de la versión: ' + oVersion + sLineBreak +
    'D - Componentes, hardware y software, y principales funcionalidades: ' +
    sApartadoD + sLineBreak + sLineBreak +
    'E - Indicación de si el sistema informático funciona exclusivamente ' +
    'como «VERI*FACTU»: ' + sApartadoE + sLineBreak +
    'F - Indicación de si permite ser usado por varios obligados ' +
    'tributarios: Sí. Factuzam permite gestionar varios obligados ' +
    'tributarios mediante empresas diferenciadas, manteniendo separados ' +
    'los datos y registros de facturación de cada obligado tributario.' +
    sLineBreak +
    'G - Tipos de firma utilizados si no es «VERI*FACTU»: ' +
    sApartadoG + sLineBreak +
    'H - Nombre y apellidos de la persona o razón social de la entidad ' +
    'productora: ' +
    ValorDeclaracion(AProductor, 'Pendiente de configurar') + sLineBreak +
    'I - Número de identificación fiscal (NIF): ' +
    ValorDeclaracion(ANif, 'Pendiente de configurar') + sLineBreak +
    'J - Dirección postal completa de contacto: ' +
    ValorDeclaracion(ADireccion, 'Pendiente de configurar') + sLineBreak +
    'K - Declaración de cumplimiento normativo: ' +
    ValorDeclaracion(AProductor, 'El productor') +
    ' deja constancia de que el sistema informático Factuzam, en la ' +
    'versión indicada y en la modalidad declarada, cumple con lo dispuesto ' +
    'en el artículo 29.2.j) de la Ley 58/2003, de 17 de diciembre, ' +
    'General Tributaria, en el Reglamento aprobado por el Real Decreto ' +
    '1007/2023, de 5 de diciembre, en la Orden HAC/1177/2024 y en las ' +
    'especificaciones publicadas por la Agencia Estatal de Administración ' +
    'Tributaria que completan dicha orden.' + sLineBreak +
    'L - Fecha y lugar de suscripción: ' +
    ValorDeclaracion(ALugar, 'Lugar pendiente de configurar') + ', ' +
    ValorDeclaracion(AFecha, 'fecha pendiente de configurar') +
    sLineBreak + sLineBreak +
    'Información adicional de cumplimiento' + sLineBreak + sLineBreak +
    'Integridad e inalterabilidad: una factura registrada no se modifica ' +
    'directamente; las correcciones se realizan mediante los registros ' +
    'posteriores que correspondan, conservando el rastro fiscal.' +
    sLineBreak + sLineBreak +
    'Trazabilidad: los registros de facturación y, cuando proceda, los ' +
    'registros de evento se encadenan mediante huella o hash para poder ' +
    'seguir su secuencia cronológica.' + sLineBreak + sLineBreak +
    'Conservación, accesibilidad y legibilidad: el sistema conserva los ' +
    'datos fiscales necesarios, permite consultar la cola de envíos y el ' +
    'registro fiscal, y facilita la revisión de incidencias.' +
    sLineBreak + sLineBreak +
    sInfoModalidad + sLineBreak + sLineBreak +
    sQr + sLineBreak + sLineBreak +
    'Responsabilidades del usuario: el obligado tributario usuario del ' +
    'sistema es responsable de la veracidad de los datos introducidos, ' +
    'de la correcta aplicación de la normativa tributaria, de custodiar ' +
    'sus copias de seguridad y de no manipular los registros de ' +
    'facturación ni de evento.' + sLineBreak + sLineBreak +
    'Ubicación de la declaración: esta declaración se encuentra ' +
    'disponible dentro de la aplicación en Verifactu > Declaración ' +
    'Responsable, de forma legible, individualizada y accesible para el ' +
    'usuario.' + sLineBreak + sLineBreak +
    'Número de instalación del SIF: ' +
    ValorDeclaracion(AInstalacion, '1') + sLineBreak +
    'Fecha de consulta de esta declaración: ' +
    FormatDateTime('dd/mm/yyyy hh:nn', Now);
end;

class procedure TfrmModalVerifactuDecl.Ejecutar(AOwner: TComponent);
var
  frm: TfrmModalVerifactuDecl;
begin
  frm := TfrmModalVerifactuDecl.Create(AOwner);
  try
    frm.CargarTexto;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalVerifactuDecl.CargarTexto;
var
  sProductor:   string;
  sNif:         string;
  sDireccion:   string;
  sLugar:       string;
  sFecha:       string;
  sInstalacion: string;
  sTextoVerifactu: string;
  sTextoNoVerifactu: string;
begin
  sProductor   := oAppParams.GetString('appVerifactuSifNombreRazon',
                                       'Alejandro Laorden Hidalgo');
  sNif         := oAppParams.GetString('appVerifactuSifNif', '');
  sDireccion   := oAppParams.GetString('appVerifactuSifDireccion', '');
  sLugar       := oAppParams.GetString('appVerifactuDeclaracionLugar', '');
  sFecha       := oAppParams.GetString('appVerifactuDeclaracionFecha', '');
  sInstalacion := oAppParams.GetString('appVerifactuIdInstalacion', '1');
  case ModoVerifactu of
    mvNoVerifactu:
      mDeclaracion.Lines.Text := ConstruirTextoDeclaracion(
        sProductor, sNif, sDireccion, sLugar, sFecha, sInstalacion,
        mvNoVerifactu);
    mvVerifactu:
      mDeclaracion.Lines.Text := ConstruirTextoDeclaracion(
        sProductor, sNif, sDireccion, sLugar, sFecha, sInstalacion,
        mvVerifactu);
    else
    begin
      sTextoVerifactu := ConstruirTextoDeclaracion(
        sProductor, sNif, sDireccion, sLugar, sFecha, sInstalacion,
        mvVerifactu);
      sTextoNoVerifactu := ConstruirTextoDeclaracion(
        sProductor, sNif, sDireccion, sLugar, sFecha, sInstalacion,
        mvNoVerifactu);
      mDeclaracion.Lines.Text :=
        'Modo fiscal actual: SIN.' + sLineBreak +
        'No hay una modalidad fiscal Verifactu activa. Se muestran las dos ' +
        'declaraciones tipo disponibles para la versión actual.' +
        sLineBreak + sLineBreak +
        sTextoVerifactu + sLineBreak + sLineBreak +
        '------------------------------------------------------------' +
        sLineBreak + sLineBreak +
        sTextoNoVerifactu;
    end;
  end;
  mDeclaracion.SelStart := 0;
end;

end.
