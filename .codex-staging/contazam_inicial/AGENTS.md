# Reglas locales de Contazam

- Idioma español en código, comentarios, interfaz y documentación.
- Delphi VCL, UniDAC y MariaDB; no introducir otro acceso a datos.
- Todas las tablas propias usan el prefijo `cza_`.
- `alexcontazam` contiene datos personales y `contazam` solo pruebas.
- Factuzam es una fuente externa de importación. No se escriben sus tablas.
- Los formularios heredan de `TfrmBase` o `TfrmMtoGen`.
- La UI coordina; el dominio y la persistencia viven en unidades separadas.
- Consultas con valores externos siempre parametrizadas.
- Sin estado global mutable, `with`, `Exit` ni `Continue` en código nuevo.
- Una instrucción por línea, indentación de dos espacios y máximo 80 columnas.
- Archivos Pascal en UTF-8 con BOM y CRLF.
- Los cambios SQL son idempotentes y nunca usan triggers ni claves foráneas.
- Toda tabla incluye las cuatro columnas de auditoría de Factuzam.
- Los asientos importados quedan en borrador hasta su revisión humana.
- Ningún identificador usa `AUTO_INCREMENT`; procede de `cza_contadores`.
- Los contadores son texto y conservan los ceros a la izquierda.
- Los PDF se almacenan en `cza_documentos` como binario, nunca como ruta.
