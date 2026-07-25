# Línea base — Fase XII-0

Fecha: 25/07/2026

Estado: **iniciada**. Este directorio no contiene cambios de
implementación; congela el punto de partida de la fase XII.

## Inventario estructural

Ejecutar desde PowerShell:

```powershell
.\inventario_parametros.ps1
```

El script es de solo lectura y enumera:

- `uses` de las dos unidades actuales;
- unidades y métodos que acceden a ambos globales;
- consumidores de las funciones libres de Caja;
- accesos desde secciones `initialization`;
- indicadores del grafo que propagará los cambios de firmas.

Resultados verificados al abrir XII-0:

- 43/25 ficheros mencionan `inLibAppParam` / `inLibCajaParam`.
- Las cláusulas `uses` reales son 39/22 dentro de `src`; `fzam.dpr`
  registra además ambas unidades.
- 116 accesos directos: 79 de App y 37 de Caja.
- 41 unidades contienen accesos a miembros; 42 mencionan los nombres
  globales al incluir la declaración.
- 15 unidades adicionales mencionan las funciones libres de Caja;
  dos menciones son comentarios y deberán excluirse del lote real.
- No hay lecturas `oAppParams.*` / `oCajaParams.*` en secciones
  `initialization`.
- La propagación estimada por firmas amplía XII-C hasta unas 87
  unidades; se dividirá en C1–C6.

## Línea base de compilación

Ejecutada el 25/07/2026 con salida temporal aislada:

| Configuración | Estado | Errores | Avisos |
|---|---:|---:|---:|
| Debug Win64 | Fallo | 1 | 18 |
| Release Win32 | Fallo | 1 | 18 |
| Release Win64 | Fallo | 1 | 18 |

Las tres configuraciones terminaron en `inLibFotos.pas(58): F2063` al
compilar `frxClass`. La causa se aisló al abrir XII-A: el selector del
script extraía `bin` en vez del número de versión y terminaba eligiendo
Studio 22.0. Las DCU de FastReport y el proyecto corresponden a Studio
37.0.

El selector quedó corregido. La matriz de XII-A con Studio 37.0 es
correcta y sus conteos de avisos coinciden exactamente con XI-D, por
lo que la incidencia de entorno queda cerrada. El resultado original
se conserva en `resultado_compilacion.txt` como evidencia del
diagnóstico.

## Línea base funcional

Pendiente de sesión manual contra BBDD de pruebas:

- captura de `inMtoAppParam`, categorías y número de claves;
- captura de `inMtoCajaParam`, categorías y número de claves;
- valor de un parámetro string, integer y boolean de cada catálogo;
- arranque hasta menú principal;
- recarga y cambio en caliente de flags de log;
- tarifa y niveles de familia al abrir Caja;
- lectura de `appVerifactuActivo` en el siguiente ciclo del hilo.

Las capturas y datos de prueba no deben contener credenciales ni datos
personales.

## Criterio de cierre de XII-0

- Decisiones de arquitectura incorporadas a la guía.
- Inventario reproducible ejecutado y coherente con la cabecera.
- Matriz de compilación registrada y sin incidencias pendientes.
- Capturas y comprobaciones funcionales registradas.
- Ningún fichero Pascal modificado como parte de XII-0.
