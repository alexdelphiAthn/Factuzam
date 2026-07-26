# Pruebas funcionales — resultados (capa automatizable)

Fecha: 26/07/2026. Entorno: MariaDB 10.11 con `factuzam_demo.sql` recién
cargado + `movimientos_indice_unico_fcve.sql` aplicado. Una sola pasada.

## Resultado: 58 comprobaciones, 0 fallos

| Batería | Qué cubre | Resultado |
|---|---|---|
| `test_iva_conversion.py` | Helpers de conversión IVA, bug `AsInteger`, `PorcentajeIvaCabecera` contra el esquema real | 12/12 |
| `test_remesas_sql.py` | SQL generado por el modal unificado (2 variantes) vs. bindings del `.dfm` y firmas de los SPs | 12/12 |
| `test_remesas_flujo.py` | Flujo completo de remesado en compra y venta | 14/14 |
| `test_borrado_factura.py` | Borrado atómico de factura (incl. fallos provocados) | 6/6 |
| `test_albaran_pedido.py` | Albarán desde pedido de venta, transaccional | 5/5 |
| `test_revertir_sesion.py` | Reversión de materialización sin errores silenciados | 4/4 |
| `test_indice_movimientos.py` | Índice único FC/VE y concurrencia de dos puestos | 5/5 |

### Lo más relevante de esta tanda (antes sin probar)

- **El riesgo nº 1 del modal unificado queda descartado**: el SELECT que
  construye `Configurar()` devuelve columnas cuyos nombres coinciden
  **exactamente** con los `DataBinding.FieldName` del `.dfm`, en las dos
  variantes. Si un alias no hubiera casado, el grid habría salido vacío en
  runtime sin error visible.
- **Contratos de los SPs verificados**: `PRC_REMC/REMV_CREAR` y
  `..._ANYADIR_EFECTO` aceptan los parámetros que pasa el código, incluido
  el parametrizado `p_NUM_EFEC` / `p_NUM_EFV` (un fallo aquí sería error en
  ejecución al pulsar Remesar).
- **Flujo de remesado end-to-end** en ambas variantes: el grid encuentra el
  efecto pendiente → se crea la remesa → se añade el efecto (resultado 1) →
  el efecto queda ligado y REMESADO → desaparece de pendientes → el reintento
  devuelve 0 (contador "Omitidos", sin duplicar) → la remesa aparece en el
  combo.
- **Bug de IVA reproducido y corregido**: con IVA del 10,5 %, el código
  antiguo (`AsInteger`) daba 110,0000 € y el nuevo da 109,5023 € — **0,50 €
  de desvío por línea**. Con IVAs enteros, nuevo y antiguo coinciden (sin
  regresión).

## Dos hallazgos de datos (no son regresiones)

1. **Series de remesa sin configurar**: `PRC_REMC_CREAR` usa el contador
   `'RP'` y `PRC_REMV_CREAR` el `'RC'` (correcto, son contadores separados),
   pero en la demo no hay serie definida para esos tipos de documento, así
   que las remesas nacen con serie `'-'`. Eso explica el `'-'` que aparece en
   los efectos existentes. **Conviene comprobar en la BBDD real** que RP y RC
   tienen serie configurada; si no, las remesas seguirán saliendo con `'-'`.
2. **Sin daño histórico por el bug de IVA**: 0 facturas con porcentaje de IVA
   decimal y 0 tipos decimales en `fza_ivas`. El truncado nunca llegó a
   afectar a datos reales; el arreglo protege de cara al futuro.

## Lo que NO puedo automatizar (y por qué)

Las pruebas de interfaz requieren arrancar `fzam.exe` con credenciales de
usuario y apuntando a una BBDD de pruebas. No tengo ni las credenciales ni
forma de garantizar a qué base apunta cada acceso directo, y varias pruebas
del plan son destructivas: ejecutarlas contra la base equivocada sería grave.
Por eso me he quedado en la capa de datos y contratos, que es donde estaban
los riesgos reales del refactor.

## Checklist de UI reducido (lo que sigue siendo necesario)

Estas ya NO hacen falta (cubiertas arriba): que el remesado cree/añada/omita
correctamente, que el borrado de factura sea atómico, que el albarán desde
pedido cuadre, que la reversión de sesión no duplique, que los movimientos no
se dupliquen, y que la conversión IVA calcule bien.

Queda por comprobar delante de la aplicación, todo en BBDD de pruebas:

1. **Grid de remesas**: que las columnas se pinten con datos (validado el
   contrato, falta el render) y que el título de la columna del tercero diga
   "Proveedor" en compra y "Cliente" en venta.
2. **Validaciones de factura**: mensaje + pestaña + foco correctos en cada
   caso (V1–V4) — es el traductor de eventos nuevo, puro UI.
3. **Maestro-detalle** de facturas: que las pestañas de detalle sigan a la
   cabecera al navegar (W1, el cableado nuevo).
4. **Conmutación de columnas** s/IVA ↔ c/IVA según la tarifa de la línea (W3,
   movida del DM al form).
5. **Estabilidad (bloque A)**: abrir un Mto, usar el chooser de guías y
   cerrar la pestaña; re-login 2–3 veces; cerrar la app con el monitor SQL
   visible.
6. **Menú y permisos** con usuario restringido; ESC y botón Salir (Fase 0).
7. **Impresión** de factura y recibos (no tocada, pero es la comprobación de
   humo clásica).

Con eso, una pasada de ~20 minutos cierra la validación completa.

## Scripts

Todos en `DESARROLLOS EN CURSO/`, reproducibles contra cualquier BBDD de
pruebas cambiando la conexión del `def conn()`.
