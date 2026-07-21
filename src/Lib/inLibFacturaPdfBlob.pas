{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturaPdfBlob                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Archivado del PDF de la factura en la propia fila de fza_facturas         }
{    (columna PDF_FAC + metadatos). Ver facturas_pdf_blob.sql.                 }
{******************************************************************************}
unit inLibFacturaPdfBlob;

interface

uses
  System.SysUtils, Uni;

/// <summary>
/// Vuelca el PDF de ARutaPdf en fza_facturas (PDF_FAC, NOMBRE_PDF_FAC,
/// TAMANO_PDF_FAC, HUELLA_PDF_FAC, INSTANTE_PDF_FAC) para la factura
/// ASerie\ANumero. "Seguro": cualquier fallo queda en el log y no
/// interrumpe la consolidación ni la impresión que lo invoca.
/// </summary>
procedure GuardarPdfFacturaEnBlob(AConn: TUniConnection;
                                  const ASerie, ANumero, ARutaPdf: string);

implementation

uses
  Data.DB, System.Hash, System.IOUtils, inLibGlobalVar, inLibLog;

procedure GuardarPdfFacturaEnBlob(AConn: TUniConnection;
                                  const ASerie, ANumero, ARutaPdf: string);
var
  Qry:     TUniQuery;
  iTamano: Int64;
  sHuella: string;
begin
  if FileExists(ARutaPdf) then
  begin
    Qry := TUniQuery.Create(nil);
    try
      try
        iTamano := TFile.GetSize(ARutaPdf);
        sHuella := UpperCase(THashSHA2.GetHashStringFromFile(ARutaPdf));
        Qry.Connection := AConn;
        Qry.SQL.Text :=
          ' UPDATE fza_facturas ' +
          ' SET PDF_FAC = :PDF, ' +
          '     NOMBRE_PDF_FAC = :NOMBRE, ' +
          '     TAMANO_PDF_FAC = :TAMANO, ' +
          '     HUELLA_PDF_FAC = :HUELLA, ' +
          '     INSTANTE_PDF_FAC = NOW(), ' +
          '     INSTANTE_MODIF = NOW(), ' +
          '     USUARIO_MODIF  = :USUARIO ' +
          ' WHERE SERIE_FAC  = :SERIE ' +
          '   AND NUMERO_FAC = :NUMERO';
        Qry.ParamByName('PDF').LoadFromFile(ARutaPdf, ftBlob);
        Qry.ParamByName('NOMBRE').AsString := ExtractFileName(ARutaPdf);
        Qry.ParamByName('TAMANO').AsLargeInt := iTamano;
        Qry.ParamByName('HUELLA').AsString := sHuella;
        Qry.ParamByName('USUARIO').AsString := oUser;
        Qry.ParamByName('SERIE').AsString := ASerie;
        Qry.ParamByName('NUMERO').AsString := ANumero;
        Qry.Execute;
        if Qry.RowsAffected > 0 then
          Log.LogInfo('PDF de la factura ' + ASerie + '\' + ANumero +
            ' archivado en fza_facturas (' + IntToStr(iTamano) + ' bytes)')
        else
          Log.LogError('PDF de ' + ASerie + '\' + ANumero +
            ' no archivado: la factura no existe en fza_facturas');
      except
        on E: Exception do
          Log.LogError('No se pudo archivar el PDF de ' + ASerie + '\' +
            ANumero + ' en fza_facturas: ' + E.Message);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

end.
