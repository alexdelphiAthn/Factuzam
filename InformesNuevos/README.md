# InformesNuevos — módulo aislado (como un programa distinto)

Carpeta **provisional** para desarrollar informes/BI nuevos **sin tocar el
código global de Factuzam** hasta que cada desarrollo se acepte. Se trata
**como un programa aparte**: nada está enganchado a `fzam.dproj` (son ficheros
en *staging*) y usa **namespace propio en BBDD** para no mezclarse con el
esquema real:

- Vistas nuevas: prefijo `vi_estadisticas_*` (solo lectura sobre `fza_*`).
- Tablas de prueba: prefijo `fzaest_*` (desechables; nunca `fza_*`).
- Sobre el esquema real `fza_*`: solo vistas, **ningún cambio**.

Regla de oro de esta carpeta:

> Si un desarrollo necesita cambiar **ficheros comunes** del proyecto
> (p. ej. `fzam.dpr`, `fzam.dproj`, `inMtoPrincipal`, `inLibGlobalVar`…),
> **NO se modifican en su sitio**. Se guarda aquí una **copia con los
> cambios** y el árbol real se deja como está. Cuando el desarrollo se
> acepte, se aplican esas copias.

## Contenido

```
InformesNuevos/
├── comparativa_periodos/        ← Panel "Comparativa de periodos" (YA HECHO)
│   ├── nuevos/                  ← Ficheros 100% nuevos (van tal cual a su ruta)
│   │   ├── src/Forms/inMtoComparativaMovimientos.pas
│   │   ├── src/Forms/inMtoComparativaMovimientos.dfm
│   │   └── DESARROLLOS EN CURSO/comparativa_movimientos.(sql|md)
│   ├── comunes_modificados/     ← COPIAS de ficheros comunes CON los cambios
│   │   ├── fzam.dpr
│   │   ├── fzam.dproj
│   │   ├── src/Core/inMtoPrincipal.(pas|dfm)
│   │   └── src/Lib/inLibGlobalVar.pas
│   └── INTEGRACION.md           ← Qué cambió en cada común y cómo aplicarlo
└── estadisticas/                ← Lab de aceleración por VISTAS (EN CURSO)
    ├── README.md
    └── vistas_estadisticas.sql
```

## Estado

| Desarrollo            | Estado            | Notas                              |
|-----------------------|-------------------|------------------------------------|
| comparativa_periodos  | Hecho, sin aceptar| Reubicado aquí; árbol real intacto |
| estadisticas (vistas) | En curso          | Solo vistas; sin cambios de esquema|

Las rutas dentro de `nuevos/` y `comunes_modificados/` **replican** la ruta
real del repo, para que aceptar un desarrollo sea copiar respetando rutas.
