# Historial de SBOM de entregas

Este registro relacionará cada SBOM con los artefactos que representa. No se considera cerrada una entrada hasta que el JSON esté saneado, validado y archivado.

| Fecha | Versión Factuzam | Plataforma | Commit | Artefacto y SHA-256 | SBOM y SHA-256 | CycloneDX | Cobertura de vulnerabilidades | Estado |
|---|---|---|---|---|---|---|---|---|
| 2026-08-25 | No fijada | Win64 Debug; análisis de fuentes | No fijado; árbol con cambios locales | No reconciliado | `factuzam.cdx.json`; `524C05045524F90BA80BBEE5CEA3278038A05AA42A5FFA30444BF1FE21C3D035` | 1.7; esquema válido | No ejecutada; estado UNKNOWN | VERIFICACIÓN |

La entrada actual documenta una resolución estable de fuentes, no una entrega. Por eso puede verificar el generador y el saneamiento, pero no cierra el SBOM de release ni identifica todavía un EXE o instalador concreto.

## Datos que debe conservar cada entrada

- herramienta y versión del generador;
- fecha y entorno de construcción controlado;
- versión, commit y plataforma;
- hashes del EXE, instalador, bibliotecas distribuidas y SBOM;
- resultado de validación del esquema;
- componentes sin identidad o sin cobertura de vulnerabilidades;
- aprobador y ubicación del expediente interno;
- correcciones o VEX asociados.

Última revisión: 2026-08-25.
