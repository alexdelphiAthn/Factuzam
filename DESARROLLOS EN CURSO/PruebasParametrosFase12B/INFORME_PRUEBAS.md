# Informe de pruebas — Fase XII-B

Fecha: 25/07/2026

## Resultado

La migración de formularios, modales y módulos de datos es correcta en
pruebas estructurales, en la regresión unitaria de XII-A y en la matriz
completa de compilación Delphi.

Queda pendiente la validación funcional interactiva contra una BBDD de
pruebas.

## Alcance comprobado

Se analizaron los 197 ficheros Pascal de:

- `src/Forms`
- `src/Modals`
- `src/DataModules`
- `src/Caja/Forms`
- `src/Caja/Modals`
- `src/Caja/DataModules`

`UniDataConn.pas` se excluye expresamente porque es un módulo directo sin
proveedor base y pertenece al barrido transversal XII-C6.

El inventario resultante contiene 30 unidades consumidoras y 61 lecturas
mediante interfaces: 20 de aplicación y 41 de caja. Cuarenta lecturas de
caja usan el proveedor heredado y `TdmCajaOpe` usa la interfaz inyectada.
En las seis carpetas quedan:

- 0 referencias a `oAppParams` / `oCajaParams`.
- 0 dependencias de `inLibAppParam` / `inLibCajaParam`.
- 0 llamadas a las funciones libres `TarifaDefecto` /
  `NivelesFamiliaArqueo`.

Tras XII-B permanecen en todo `src` 50 accesos directos a los alias en 15
unidades (46 App y 4 Caja), todos fuera de este lote o en
`UniDataConn.pas`. Corresponden a XII-C y a la retirada final de XII-D.

## Excepción de `TdmCajaOpe`

`TdmCajaOpe` desciende directamente de `TDataModule`, por lo que no puede
obtener `ParametrosCaja` mediante `TdmBase`. Se aplicó inyección explícita:

- el constructor exige `IParametrosCaja`;
- la interfaz se valida y conserva en `FParametrosCaja`;
- `GetTarifaDefault` usa `FParametrosCaja.TarifaDefecto`;
- los tres llamantes propagan su propiedad `ParametrosCaja`.

## Pruebas automáticas

`ejecutar_pruebas.ps1`:

- regresión estructural XII-A: correcta;
- prueba unitaria del motor Win32: correcta;
- prueba unitaria del motor Win64: correcta;
- estructura específica XII-B: correcta;
- `factuzam_original.sql`: intacto.

`ejecutar_compilacion.ps1`, con Studio 37.0:

| Configuración | Resultado | Errores | Avisos |
|---|---:|---:|---:|
| Debug Win64 | Correcta | 0 | 110 |
| Release Win32 | Correcta | 0 | 107 |
| Release Win64 | Correcta | 0 | 109 |

Los avisos coinciden exactamente con la línea base de XII-A y XI-D.

La implementación no requirió cambios DFM. Los DFM que ya estaban
modificados en el árbol de trabajo antes de este lote se conservaron sin
alterar.

## Validación funcional pendiente

En una instalación de pruebas:

1. Completar una venta en `inMtoCajaOpe`, incluido cobro por fases,
   selección de vale, empleado por defecto y lectura por scanner.
2. Generar al menos un PDF y un Excel desde los modales de impresión.
3. Verificar `appStockOcultarCeros` en la consulta de stock.
4. Exportar desde inventarios y documentos de trabajo.
5. Confirmar la tarifa por defecto al crear clientes, pedidos, albaranes,
   facturas y sesiones de compra.
