unit inLibDefaultValues;

interface

uses
  inMtoGenSearch, // Necesitamos ver el formulario para configurarlo
  System.SysUtils;

type
  // Enumerado para evitar errores de tipeo con strings ('ARTICULO' vs 'Articulo')
  TEntidadSistema = (esArticulo, esCliente, esEmpresa, esFamilia);

  TLibDefaults = class
  public
    // Este método configura TODO: el Grid (vista) y el Alta Rápida (tabla física)
    class procedure Configurar(AForm: TfrmMtoSearch; AEntidad: TEntidadSistema;
                               bConAltaRapida: Boolean = False );
  end;

implementation

{ TLibDefaults }

class procedure TLibDefaults.Configurar(AForm: TfrmMtoSearch;
                                        AEntidad: TEntidadSistema;
                                        bConAltaRapida: Boolean);
begin
  // 1. Activar funcionalidad base
  AForm.FConfigAlta.Activo := True;

  case AEntidad of
    // -------------------------------------------------------------------------
    // CONFIGURACIÓN DE ARTÍCULOS
    // -------------------------------------------------------------------------
    esArticulo:
      begin
        // A. Configuración LECTURA (Lo que se ve en el Grid)
        // Usamos la vista para que el usuario vea datos completos (Stock, etc.)
        // Asegúrate de que AForm tenga acceso a modificar su QueryPrincipal o unqryPerfiles
//        if Assigned(AForm.unqryPerfiles) then
//        begin
//          AForm.unqryPerfiles.Close;
//          AForm.unqryPerfiles.SQL.Text := 'SELECT * FROM vi_articulos ORDER BY DESCRIPCION_ARTICULO';
//          // AForm.unqryPerfiles.Open; // Opcional, o dejar que el form lo abra al mostrarse
//        end;

        if bConAltaRapida then
        begin
          AForm.FConfigAlta.TituloVentana := 'Alta Rápida de Artículo';
          AForm.FConfigAlta.Tabla := 'fza_articulos';         // Tabla física escritura
          AForm.FConfigAlta.CampoCodigo := 'CODIGO_ARTICULO'; // Campo PK
          AForm.FConfigAlta.CampoDescripcion := 'DESCRIPCION_ARTICULO';

          // Al llamar a esto, el botón se hace visible y se cargan los defaults
          AForm.CargarDefaultsDesdeBD('fza_articulos');
        end;
      end;

    // -------------------------------------------------------------------------
    // CONFIGURACIÓN DE CLIENTES
    // -------------------------------------------------------------------------
    esCliente:
      begin
        AForm.Caption := 'Búsqueda de Clientes';
        AForm.FConfigAlta.TituloVentana := 'Alta Rápida de Cliente';

        // A. LECTURA
        if Assigned(AForm.unqryPerfiles) then
        begin
          AForm.unqryPerfiles.Close;
          AForm.unqryPerfiles.SQL.Text := 'SELECT * FROM vi_clientes ORDER BY RAZON_SOCIAL';
        end;

        // B. ESCRITURA
        AForm.FConfigAlta.Tabla := 'fza_clientes';
        AForm.FConfigAlta.CampoCodigo := 'CODIGO_CLIENTE';
        AForm.FConfigAlta.CampoDescripcion := 'RAZON_SOCIAL';

        // C. DEFAULTS (Busca en BD la config de 'fza_clientes' y el contador 'CL')
        AForm.CargarDefaultsDesdeBD('fza_clientes');
      end;

    // -------------------------------------------------------------------------
    // CONFIGURACIÓN DE EMPRESAS (Ejemplo simple)
    // -------------------------------------------------------------------------
    esEmpresa:
      begin
         AForm.FConfigAlta.TituloVentana := 'Nueva Empresa';
         AForm.FConfigAlta.Tabla := 'fza_empresas';
         AForm.FConfigAlta.CampoCodigo := 'CODIGO_EMPRESA';
         AForm.FConfigAlta.CampoDescripcion := 'NOMBRE_EMPRESA';
         AForm.CargarDefaultsDesdeBD('fza_empresas');
      end;
  end;
end;

end.