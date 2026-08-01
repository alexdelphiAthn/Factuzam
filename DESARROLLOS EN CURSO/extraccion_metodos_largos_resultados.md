# Extracción de los métodos más largos

Fecha: 01/08/2026. Refactorización estructural sin cambios de API ni commit.

## Balance

| Método | Antes | Después |
|---|---:|---:|
| `TFormVisualizador.ProcesarComandosESCPOS` | 312 | 34 |
| `TTiraCajaTicket.Imprimir` | 290 | 30 |
| `ImprimirT` | 289 | 32 |
| `TfrmMtoPrincipal.InicializarAplicacion` | 266 | 22 |

`ImprimirT` medía 289 líneas al comenzar esta intervención; el inventario
anterior indicaba 286. `InicializarAplicacion` medía 266 frente a las 268 del
inventario.

El máximo global baja de 312 a 286 líneas. Los métodos productivos por encima
de 120 líneas bajan de 120 a 116 y los que superan 200 líneas, de 33 a 28.

## Diseño aplicado

- El intérprete ESC/POS delega lectura, vaciado de texto y familias de comandos
  `ESC`, `GS`, código de barras, QR e imagen ráster en operaciones privadas.
- La tira de caja usa `TImpresorTiraCajaTicket`, colaborador privado de la
  unidad que conserva agrupación, acumuladores, subtotales, cierre y emisión.
- El ticket de venta usa `TImpresorTicketVenta`, colaborador privado que separa
  preparación, cabecera, artículos, importes, cobros, IVA, códigos y emisión.
- El arranque principal queda como coordinador de fases explícitas: contexto,
  infraestructura, sesión, datos, procesos, estado, tema y presentación.

Los colaboradores son específicos de su consumidor. No se ha creado ningún
repositorio generalista ni se ha cambiado la interfaz pública de las unidades.

## No regresión

Los trinquetes estructurales protegen las cuatro fachadas y los métodos
extraídos. Ninguno de estos flujos supera 100 líneas. Los límites globales se
han reducido a 116 métodos por encima de 120 líneas, 286 líneas como máximo y
28 métodos por encima de 200 líneas.

## Verificación

- aplicación principal: compilación correcta en Debug/Win32 y Debug/Win64;
- pruebas DUnitX: compilación correcta en ambas arquitecturas;
- pruebas DUnitX: 545 de 545 correctas en Win32 y Win64, sin fugas;
- comprobadores de métodos y flujos largos: correctos;
- comprobadores de estilo y dependencias entre capas: correctos;
- `git diff --check`: sin errores.

Queda recomendada una comprobación manual con impresora o emulador ESC/POS
para validar el resultado gráfico de tickets, códigos QR, códigos de barras,
imágenes ráster, corte y apertura del cajón.
