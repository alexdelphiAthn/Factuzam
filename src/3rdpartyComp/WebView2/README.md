# Visor web de ayuda

El foro y el manual se muestran mediante `Vcl.Edge.TEdgeBrowser`, incluido
en Delphi, para admitir el HTML, CSS y JavaScript del manual actual dentro
de Factuzam. La ventana ofrece Atrás, Adelante, Recargar y Salir.

## Distribución

El equipo cliente necesita Microsoft Edge WebView2 Runtime. Es un motor
integrado: no abre el navegador de escritorio ni depende de permitir su
ejecución a los empleados. Las políticas del equipo deben permitir WebView2.

El paso común `CoreBuild` de `fzam.dproj` copia automáticamente el cargador
de la arquitectura correcta y su licencia junto a `fzam.exe`, tanto en
`Make` (Compilar desde Delphi) como en `Build` (Construir). El instalador demo
incluye ambos archivos. Las actualizaciones manuales deben distribuirlos
también. El runtime se administra por separado en el equipo cliente.

El perfil se guarda en la carpeta local del usuario que gestiona `TEdgeBrowser`,
separado del navegador de escritorio. «Ventana interna» no implica modo
incógnito: las cookies del foro pueden conservarse entre aperturas.

## Procedencia verificable

- Paquete oficial: Microsoft.Web.WebView2 **1.0.3650.58**.
- Descarga: https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/1.0.3650.58
- Archivos originales: `build/native/x86/WebView2Loader.dll`,
  `build/native/x64/WebView2Loader.dll` y `LICENSE.txt`.
- Ambas DLL tienen firma Authenticode válida de Microsoft Corporation.
- SHA-256 x86:
  `44AB92C2246EBFB5F98AA5726626FB44BEB61543F2EF1803338AF9FD295E63F0`.
- SHA-256 x64:
  `8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C`.

Documentación de distribución:
https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution
