program PruebaFirmaDelphi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibFirmaApi in '..\inLibFirmaApi.pas',
  inLibProteccionWindows in '..\inLibProteccionWindows.pas';

var
  aFirma: TBytes;
  aMensaje: TBytes;
  oIdentidad: TIdentidadEmisora;
  sFirma: string;
begin
  oIdentidad := TFirmaApi.CargarOCrearIdentidad;
  aMensaje := TEncoding.UTF8.GetBytes('Prueba Delphi a PHP');
  try
    aFirma := TFirmaApi.Firmar(oIdentidad, aMensaje);
    try
      sFirma := TFirmaApi.Base64UrlCodificar(aFirma);
      WriteLn('{');
      WriteLn('  "clave_publica":"' +
        TFirmaApi.Base64UrlCodificar(oIdentidad.ClavePublica) + '",');
      WriteLn('  "mensaje":"' +
        TFirmaApi.Base64UrlCodificar(aMensaje) + '",');
      WriteLn('  "firma_1":"' + Copy(sFirma, 1, 43) + '",');
      WriteLn('  "firma_2":"' + Copy(sFirma, 44, MaxInt) + '"');
      WriteLn('}');
    finally
      sFirma := '';
      TFirmaApi.Limpiar(aFirma);
    end;
  finally
    TFirmaApi.Limpiar(aMensaje);
    TFirmaApi.Limpiar(oIdentidad.ClavePrivada);
    TFirmaApi.Limpiar(oIdentidad.ClavePublica);
  end;
end.
