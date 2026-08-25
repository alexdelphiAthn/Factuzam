# Copie estas asignaciones a la configuración del runner o de su terminal.
# Sustituya los marcadores por directorios instalados; no añada el archivo
# resultante al repositorio.

$env:FACTUZAM_DELPHI_ROOT = '<raiz-de-rad-studio>'
$env:FACTUZAM_DEVEXPRESS_ROOT = '<raiz-library-rsXX-de-devexpress>'
$env:FACTUZAM_FASTREPORT_ROOT = '<raiz-vcl-de-fastreport>'
$env:FACTUZAM_UNIDAC_ROOT = '<raiz-lib-de-unidac>'

# Opcionales para Pascal Analyzer. Las raices de fuentes se detectan a partir
# de las anteriores cuando las instalaciones conservan la estructura normal.
# $env:FACTUZAM_PASCAL_ANALYZER = '<ruta-a-palcmd.exe>'
# $env:FACTUZAM_DEVEXPRESS_SOURCE_ROOT = '<raiz-vcl-de-devexpress>'
# $env:FACTUZAM_FASTREPORT_SOURCE_ROOT = '<raiz-sources-de-fastreport>'

# Solo es necesario para un proyecto DUnitX que importe las propiedades
# compartidas con FactuzamRequiereDUnitX=true.
$env:FACTUZAM_DUNITX_ROOT = '<directorio-source-de-dunitx>'
