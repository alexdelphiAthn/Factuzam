program PruebaIntegracionPerfilesVentana;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibConfiguracion in '..\src\Lib\inLibConfiguracion.pas',
  inLibCifrado in '..\src\Lib\inLibCifrado.pas',
  inLibPerfilesVentanaTipos in
    '..\src\Lib\inLibPerfilesVentanaTipos.pas',
  UniDataConexion in '..\src\DataModules\UniDataConexion.pas',
  UniDataPerfilesVentana in
    '..\src\DataModules\UniDataPerfilesVentana.pas';

const
  FormularioPrueba = 'TfrmPruebaIntegracionPerfilVentana';

procedure Comprobar(ACondicion: Boolean; const AMensaje: string);
begin
  if not ACondicion then
  begin
    raise Exception.Create(AMensaje);
  end;
end;

var
  aColumnas: TPerfilesColumnasContazam;
  aColumnasLeidas: TPerfilesColumnasContazam;
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oPerfil: TPerfilVentanaContazam;
  oPerfilLeido: TPerfilVentanaContazam;
  oRepositorio: TRepositorioPerfilesVentana;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    oConfiguracion := TConfiguracionContazam.Cargar;
    oConexion := TdmConexion.Create(nil, oConfiguracion);
    try
      oRepositorio := TRepositorioPerfilesVentana.Create(
        oConexion.Conexion,
        oConfiguracion.Empresa,
        oConfiguracion.UsuarioAplicacion);
      try
        oRepositorio.Eliminar(FormularioPrueba);
        oPerfil := Default(TPerfilVentanaContazam);
        oPerfil.Nombre := 'Ventana de prueba';
        oPerfil.PosicionIzquierda := 21;
        oPerfil.PosicionSuperior := 34;
        oPerfil.Ancho := 900;
        oPerfil.Alto := 600;
        oPerfil.Estado := 'NORMAL';
        oPerfil.PestanaActiva := 'tsFicha';
        SetLength(aColumnas, 2);
        aColumnas[0].Grid := 'cxGrdDBTabPrin';
        aColumnas[0].Campo := 'CODIGO_EMP';
        aColumnas[0].Nombre := 'Código';
        aColumnas[0].Orden := 0;
        aColumnas[0].EsVisible := True;
        aColumnas[0].Ancho := 120;
        aColumnas[1].Grid := 'cxGrdDBTabPrin';
        aColumnas[1].Campo := 'NOMBRE_EMP';
        aColumnas[1].Nombre := 'Nombre de la empresa';
        aColumnas[1].Orden := 1;
        aColumnas[1].EsVisible := False;
        aColumnas[1].Ancho := 320;
        oRepositorio.Guardar(FormularioPrueba, oPerfil, aColumnas);
        Comprobar(
          oRepositorio.Cargar(
            FormularioPrueba,
            oPerfilLeido,
            aColumnasLeidas),
          'No se ha recuperado el perfil guardado.');
        Comprobar(
          oPerfilLeido.PestanaActiva = 'tsFicha',
          'No se ha conservado la pestaña activa.');
        Comprobar(
          Length(aColumnasLeidas) = 2,
          'No se han recuperado las dos columnas.');
        Comprobar(
          aColumnasLeidas[0].Nombre = 'Código',
          'No se ha conservado el nombre de la columna.');
        Comprobar(
          (aColumnasLeidas[1].Ancho = 320) and
          not aColumnasLeidas[1].EsVisible,
          'No se han conservado ancho y visibilidad.');
        oRepositorio.Eliminar(FormularioPrueba);
        Comprobar(
          not oRepositorio.Cargar(
            FormularioPrueba,
            oPerfilLeido,
            aColumnasLeidas),
          'El perfil no se ha eliminado al resetearlo.');
      finally
        FreeAndNil(oRepositorio);
      end;
    finally
      FreeAndNil(oConexion);
    end;
    Writeln('OK: perfiles de ventana guardados y reseteados.');
  except
    on E: Exception do
    begin
      Writeln('ERROR: ' + E.Message);
      Halt(1);
    end;
  end;
end.
