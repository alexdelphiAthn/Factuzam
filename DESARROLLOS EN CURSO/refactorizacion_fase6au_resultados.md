# Fase 6AU — carga de pedidos PrestaShop

Fecha: 29/07/2026. D4.11, undécima tanda de métodos largos. Sin commit
manual.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `TPrestaConn.CargarPedido` | 312 | 11 | **-301** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibPrestaImporter` completa | 485 | 548 | **+63** |

La unidad crece un 13,0 %. D4.11 reduce complejidad, no volumen:
`CargarPedido` queda como fachada y el colaborador privado
`TCargaPedidoPresta` reparte el protocolo entre dieciséis operaciones.
Todas tienen consumidor y ninguna supera 37 líneas.

No cambia la API pública ni se crea otra unidad. El estado temporal de
la importación queda encapsulado en el colaborador y el `TOrder` solo
se transfiere al llamador cuando termina la carga principal.

## Implementación

`TCargaPedidoPresta` separa:

- petición REST y selección del nodo XML esperado;
- lectura del pedido base y sus identificadores relacionados;
- cliente;
- direcciones de entrega y facturación;
- provincia asociada a cada dirección;
- importes y cabecera económica;
- transportista y estado del pedido;
- líneas de artículos;
- hilo y mensajes del cliente;
- coordinación completa y transferencia del resultado.

Se conserva el orden de materialización:

1. pedido base;
2. cliente;
3. dirección de entrega;
4. dirección de facturación o copia de la entrega;
5. cabecera económica;
6. transportista;
7. estado del pedido;
8. líneas;
9. mensajes opcionales.

También se conservan:

- los mismos recursos, filtros y campos de la API;
- la prioridad `vatnumber` → `vat_number` en entrega;
- la prioridad inversa en facturación;
- la copia mediante `PutAdressDelinbil` cuando ambas direcciones
  coinciden;
- la lectura del nombre de estado con o sin nodo `language`;
- el recorrido por hermanos de líneas y mensajes;
- la conversión decimal existente;
- la tolerancia a pedidos sin hilo de mensajes.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.11:

- `CargarPedido` no puede superar 100 líneas;
- las dieciséis operaciones privadas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protege la secuencia completa del protocolo;
- se protege la fachada y su `FreeAndNil`;
- se protegen recursos REST, fallbacks de NIF, copia de dirección,
  recorridos XML y mensajes opcionales;
- el límite global baja de 40 a 39 métodos mayores de 200 líneas.

Resultado: fachada de 11 líneas, colaborador máximo de 37 y 39 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La aplicación principal se reconstruyó con Delphi 37 en Release/Win32
y Release/Win64 dentro de `build/validacion_d411`. Ambas plataformas
compilan y enlazan el refactor sin errores.

La matriz DUnitX general no enlaza `inLibPrestaImporter`, pero se
recompiló después de todas sus fuentes para controlar regresiones
concurrentes:

| Configuración | Compilación | Pruebas | Fugas | Fallos/errores |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 225/228 | 0 | 1/2 |
| Release / Win64 | 0 errores | 227/228 | 0 | 1/0 |
| Debug / Win32 | 0 errores | 227/228 | 0 | 1/0 |
| Release / Win32 | 0 errores | 227/228 | 0 | 1/0 |

La única prueba roja común sigue siendo ajena a D4.11:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

Debug/Win64 añade dos errores del desarrollo paralelo recién
incorporado:

- `PruebasCatalogoSql.PerfilActivoValido_DevuelvePersonalizacion`;
- `PruebasCatalogoSql.PerfilConParametrosInvalidos_DevuelveSqlBase`.

Ambos terminan con `Operation not allowed on sorted list`. Las otras
tres configuraciones pasan esos casos.

También pasan:

- el comprobador de flujos largos;
- el comprobador de acoplamiento sobre 424 unidades;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- `git diff --check`.

## Validación funcional pendiente

Con una tienda PrestaShop de pruebas y credenciales válidas:

1. Importar un pedido con direcciones de entrega y facturación iguales.
2. Importar otro con direcciones distintas y provincias informadas.
3. Probar respuestas con `vatnumber` y con `vat_number`.
4. Comprobar importes, forma de pago, referencia, transportista y
   estado traducido.
5. Importar varias líneas y verificar referencias, EAN, atributos,
   cantidades y precios con/sin IVA.
6. Probar un pedido con mensajes y otro sin hilo.
7. Forzar una respuesta REST o XML inválida antes de los mensajes y
   confirmar que el error principal se propaga.
8. Forzar un error solo en mensajes y confirmar que el pedido sigue
   siendo importable.

El siguiente fascículo es **D4.12**:
`TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion`, actualmente con
310 líneas.
