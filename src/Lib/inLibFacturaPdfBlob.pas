{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturaPdfBlob                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Archivado del PDF de la factura en la propia fila de fza_facturas         }
{    (columna PDF_FAC + metadatos). Ver facturas_pdf_blob.sql.                 }
{    La persistencia entra por IRepositorioPdfFactura.                         }
{******************************************************************************}
unit inLibFacturaPdfBlob;

interface

uses
  System.SysUtils, inLibContextoSesionIntf,
  inLibFacturasPersistenciaIntf, inLibLogIntf;

/// <summary>
/// Vuelca el PDF de ARutaPdf en fza_facturas (PDF_FAC, NOMBRE_PDF_FAC,
/// TAMANO_PDF_FAC, HUELLA_PDF_FAC, INSTANTE_PDF_FAC, FORMATO_PDF_FAC)
/// para la factura ASerie\ANumero. AFormato es el formato de impresión
/// usado (sElegido del modal; vacío se registra como 'Predeterminado').
/// "Seguro": cualquier fallo queda en el log y no interrumpe la
/// consolidación ni la impresión que lo invoca.
/// </summary>
procedure GuardarPdfFacturaEnBlob(
                                  const ARepositorio: IRepositorioPdfFactura;
                                  const AContextoSesion:
                                  IContextoSesionAplicacion;
                                  const ASerie, ANumero, ARutaPdf: string;
                                  const AFormato: string = '';
                                  const ARegistroLog: IRegistroLog = nil);

implementation

uses
  System.IOUtils, inLibRegistroLogNulo;

procedure GuardarPdfFacturaEnBlob(
                                  const ARepositorio: IRepositorioPdfFactura;
                                  const AContextoSesion:
                                  IContextoSesionAplicacion;
                                  const ASerie, ANumero, ARutaPdf: string;
                                  const AFormato: string;
                                  const ARegistroLog: IRegistroLog);
var
  iTamano:  Int64;
  sFormato: string;
  RegistroLog: IRegistroLog;
begin
  RegistroLog := ARegistroLog;
  if not Assigned(RegistroLog) then
    RegistroLog := CrearRegistroLogNulo;
  if FileExists(ARutaPdf) then
  begin
    sFormato := Trim(AFormato);
    if sFormato = '' then
      sFormato := 'Predeterminado';
    try
      iTamano := TFile.GetSize(ARutaPdf);
      if ARepositorio.GuardarPdf(
           ASerie,
           ANumero,
           ARutaPdf,
           sFormato,
           AContextoSesion.Identidad.Usuario) then
        RegistroLog.RegistrarInformacion(
          'PDF de la factura ' + ASerie + '\' + ANumero +
          ' archivado en fza_facturas (' + IntToStr(iTamano) + ' bytes)')
      else
        RegistroLog.RegistrarError('PDF de ' + ASerie + '\' + ANumero +
          ' no archivado: la factura no existe en fza_facturas');
    except
      on E: Exception do
        RegistroLog.RegistrarError(
          'No se pudo archivar el PDF de ' + ASerie + '\' +
          ANumero + ' en fza_facturas: ' + E.Message);
    end;
  end;
end;

end.
