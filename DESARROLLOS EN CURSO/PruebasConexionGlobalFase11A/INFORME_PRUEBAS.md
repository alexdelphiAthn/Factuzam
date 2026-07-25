# Informe de pruebas - Conexión global Fase XI-A

Fecha: 25/07/2026

## Resultado

XI-A queda aplicada y supera las once comprobaciones estructurales y la
matriz de compilación Delphi. La subfase queda validada en Windows sin
errores de compilación.

## Alcance

Formularios, modales y módulos de datos cuya clase desciende de
`TfrmBase` o de `TdmBase`, y solo las referencias que viven dentro de un
método de esa clase. Ambas clases base ya publican
`ConexionPrincipal: TUniConnection`, resuelta desde el
`IServicioConexiones` que heredan del propietario, así que la sustitución
no necesita inyectar nada nuevo.

El plan completo de la fase, con el reparto de XI-B, XI-C y XI-D, está en
`DESARROLLOS EN CURSO/retirada_conexion_global.md`.

## Cambio aplicado

`oConn` (y su forma cualificada `inLibGlobalVar.oConn`) pasa a
`ConexionPrincipal` en **754 líneas de 78 unidades**, repartidas en
`src/Core`, `src/Forms`, `src/Modals`, `src/DataModules`,
`src/Caja/Forms`, `src/Caja/Modals` y `src/verifactu`.

Se han verificado una a una las 78 clases receptoras: todas descienden de
`TfrmBase` o de `TdmBase`, incluidas las cadenas intermedias
`TfrmMtoGen`, `TfrmMtoSearch`, `TfrmMtoFacturasBase`, `TfrmPrint`,
`TfrmPrintMultiFiltro` y `TfrmModalAceptCancel`.

Cuatro ajustes no mecánicos:

1. En `TfrmMtoComprasSesiones.MaterializarSesionConTx` había una variable
   **local** llamada `oConn` que se inicializaba desde la global. Se
   renombra a `oConexion` y se inicializa desde `ConexionPrincipal`, para
   que la barrera anti-regresión pueda buscar el identificador sin falsos
   positivos.
2. Trece líneas pasaban de 80 columnas al crecer el identificador. Se
   reajusta su corte sin cambiar la lógica.
3. Al reajustar esas líneas se han separado en dos cuatro `if ... then`
   que llevaban la acción en la misma línea, conforme al libro de estilo.
4. Dos referencias de `inMtoFacturasBase` vivían bajo una cabecera de
   método partida en dos líneas (`procedure TfrmMtoFacturasBase.` y el
   nombre debajo). El primer barrido no las reconoció como método; se han
   migrado en una segunda pasada con el reconocedor corregido.

## Referencias pendientes

| Estado | Líneas | Apariciones | Unidades |
| --- | ---: | ---: | ---: |
| Al abrir XI-A | 933 | 939 | 111 |
| Tras XI-A | 179 | 183 | 38 |

Las 183 apariciones restantes, distribuidas en 179 líneas, son por
subfase:

- **XI-B**, 68 líneas y apariciones: los consumidores de la capa visual
  y de datos
  que declaran su clase sobre `TForm` o `TDataModule`
  (`UniDataTraspaso`, `UniDataCaja`, `inMtoStockConsulta`,
  `UniDataConsultaOpe`, `inMtoModalFacturarAlbaranesFechas`) más las
  rutinas de unidad sin `Self` de `inMtoPrincipal`, `inMtoAppParam`,
  `inMtoModalFacturarTicket`, `inMtoModalSerieFechaFactura` y
  `inMtoModalVerifactuDecl`.
- **XI-C**, 108 líneas y 112 apariciones: las librerías `inLib*` sin
  formulario,
  incluida `inLibAtributosPaleta`.
- **XI-D**, 3 referencias: la declaración y la inicialización de
  `inLibGlobalVar` y el puente `oConn := FDmConn.conUni;` de la raíz.

## Prueba estructural de XI-A

Script:
`PruebasConexionGlobalFase11A.ps1`

Resultado: **11 comprobaciones, 11 correctas y 0 fallos**.

Las comprobaciones son:

1. Ninguna unidad ajena a la lista de pendientes de XI-B/C/D lee la
   conexión global.
2. Las referencias pendientes no crecen por encima de 179 líneas y 183
   apariciones.
3. `TfrmBase` publica `ConexionPrincipal`.
4. `TdmBase` publica `ConexionPrincipal`.
5. Las 78 unidades migradas resuelven la conexión por
   `ConexionPrincipal`.
6. Ninguna unidad migrada declara una variable local llamada `oConn`.
7. La raíz conserva el puente de compatibilidad hasta XI-D.
8. Ninguna línea que contiene `ConexionPrincipal` pasa de 80 columnas.
9. Se conservan los 253 enlaces persistentes de 52 DFM.
10. No se modifica ningún DFM ajeno a las dos conversiones de herencia
    visual incorporadas después en XI-B1.
11. `factuzam_original.sql` permanece intacto.

La comprobación 1 es el corazón de la barrera: la lista de pendientes es
explícita, así que cualquier unidad nueva que vuelva a leer la global
falla la prueba aunque el total de referencias baje.

El script `.ps1` se ha ejecutado directamente con PowerShell en Windows.
La barrera contabiliza por separado 179 líneas y 183 apariciones, ya que
cuatro líneas contienen dos lecturas de `oConn`.

## Compilación

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

Delphi conserva avisos e indicaciones ya presentes en el proyecto. No se
ha detectado ningún error nuevo causado por la sustitución.

Además de la compilación, se ha comprobado que:

- ninguna de las 78 unidades declara un identificador propio llamado
  `ConexionPrincipal` que pudiera ensombrecer la propiedad heredada;
- ninguna sustitución cae fuera de un método de la clase que hereda la
  propiedad, ni en la sección `interface`, ni en un `uses`, ni en una
  rutina de unidad.

## Regresión automatizada

| Batería | Resultado |
| --- | ---: |
| Conexión global Fase XI-A | 11/11 |
| Contexto de sesión Fase X-D | 11/11 |
| Contexto de sesión Fase X-C | 17/17 |
| Contexto de sesión Fase X-B | 13/13 |
| Contexto de sesión Fase X-A | 14/14 |
| Contexto de sesión Fase VIII | 18/18 |
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| Total | 121/121 |

La prueba de X-D admitía temporalmente los `uses inLibGlobalVar` de
unidades que ya consumían `ConexionPrincipal`. XI-D ha retirado esa
excepción y completado la limpieza de importaciones.

## Compatibilidad

- El puente `oConn := FDmConn.conUni;` de `inMtoPrincipal` se conserva a
  propósito: las librerías de XI-C todavía lo necesitan.
- No se retira ningún `uses inLibGlobalVar`, aunque tras XI-A varias
  unidades ya no consumen ningún símbolo de esa unidad. La limpieza se
  hace en XI-D, cuando se pueda comprobar compilando, igual que hizo X-D
  con las seis variables de sesión.
- Se conservan los 253 enlaces persistentes
  `Connection = dmConn.conUni` de 52 ficheros DFM.
- En XI-A no se modificó ningún DFM. La barrera admite después los dos
  cambios de raíz `object` → `inherited` aplicados por XI-B1 y rechaza
  cualquier otro DFM.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` permanece intacto.
- No se ha hecho ningún commit ni ningún push.

## Estado posterior: XI-D aplicada

La prueba de la Fase X-D ya no incluye `oConn` en
`$patronSimbolosGlobales`. La barrera XI-D exige cero referencias en
`src` y `fzam.dpr`.

## Prueba funcional recomendada

Con una base de datos de desarrollo, y prestando atención a los puntos
donde la conexión se usa para abrir o cerrar transacciones:

1. iniciar sesión y abrir mantenimientos de ventas, compras, artículos,
   inventarios, clientes y proveedores;
2. crear y anular una factura, un albarán, un pedido y una devolución de
   compra, comprobando contadores y auditoría;
3. materializar una sesión de compra con «un documento por almacén», que
   es el flujo cuya variable local se ha renombrado, y forzar un fallo a
   mitad para comprobar que el rollback sigue dejando la BBDD limpia;
4. ejecutar el árbol de permisos: cargar explícitos, establecer, heredar
   y copiar entre sujetos;
5. abrir caja, registrar una operación y un traspaso, e imprimir sus
   tickets;
6. lanzar los modales de impresión de facturas, efectos, arqueos,
   depósitos, pagos y balances;
7. abrir varias pestañas de mantenimiento a la vez, para confirmar que la
   reasignación de conexiones por pestaña sigue funcionando.
