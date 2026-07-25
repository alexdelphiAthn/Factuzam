# Informe de pruebas — Fase XII-C

Fecha: 25/07/2026

## Resultado

La retirada de parámetros globales en librerías, colas e hilos es
correcta en los controles estructurales, en la regresión unitaria de
XII-A y en la matriz completa de compilación Delphi.

La aplicación ya puede compilarse y ejecutarse para pruebas. XII-D
eliminará los tres alias de transición, pero no es necesaria para probar
esta versión.

Queda pendiente la validación funcional interactiva contra una BBDD de
pruebas.

## Alcance comprobado

Se analizaron recursivamente los 613 ficheros Pascal de `src`. El
resultado estructural es:

- 0 referencias a `oAppParams` / `oCajaParams` fuera de
  `src/Core/inMtoPrincipal.pas`, `src/Lib/inLibAppParam.pas` y
  `src/Caja/Lib/inLibCajaParam.pas`.
- 0 dependencias de `inLibAppParam` / `inLibCajaParam` fuera de esas
  tres unidades.
- `inLibLog` continúa desacoplado de las unidades puente.
- `factuzam_original.sql` permanece intacto.

## Inyección en colas y objetos directos

- `THiloVentasWsCola` conserva y libera `IParametrosAplicacion`.
- La API estática de `TVentasWsCola` recibe `IParametrosCaja` en
  encolado, eventos y adjuntos.
- `THiloVerifactuCola` conserva y libera `IParametrosAplicacion` e
  `IParametrosCaja`.
- `TdmCajaOpe` recibe App y Caja en su constructor para mantener el
  registro fiscal dentro de la transacción de venta.
- `TdmConn` recibe App desde la raíz y ya no consulta `inLibAppParam`
  en el tratamiento de errores.
- `GetImpresoraCaja` recibe `IParametrosCaja`.

## Pruebas automáticas

`ejecutar_pruebas.ps1`:

- regresión estructural XII-A: correcta;
- prueba unitaria del motor Win32: correcta;
- prueba unitaria del motor Win64: correcta;
- estructura específica XII-C: correcta;
- `factuzam_original.sql`: intacto.

`ejecutar_compilacion.ps1`, con Studio 37.0:

| Configuración | Resultado | Errores | Avisos |
|---|---:|---:|---:|
| Debug Win64 | Correcta | 0 | 110 |
| Release Win32 | Correcta | 0 | 107 |
| Release Win64 | Correcta | 0 | 109 |

Los avisos coinciden con la línea base de XII-A y XII-B.

## Validación funcional pendiente

En una instalación de pruebas:

1. Arrancar, iniciar sesión y cerrar la aplicación comprobando el log.
2. Completar una venta y una anulación en cada modo fiscal.
3. En PRE, generar registro, QR y envío Verifactu y comprobar el
   reintento de la cola.
4. Activar la cola de ventas WS y comprobar envío, error y reintento.
5. Generar ticket, tira de caja, PDF y Excel con y sin QR.
6. Probar fotos locales/nube, correo e inventarios mediante API.
7. Cambiar los flags de log y el modo de depuración en caliente.
8. Validar el reloj fiscal y la exportación/verificación NO VERI*FACTU.

## Reproducción

- Pruebas: `ejecutar_pruebas.cmd`
- Matriz Delphi: `ejecutar_compilacion.cmd`
