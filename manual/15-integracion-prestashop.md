# 15 · Integración con PrestaShop

[◀ Volver al índice](README.md)

La integración con **PrestaShop** permite que Factuzam sea el origen de los
precios y del stock de la tienda online cuando se autoriza expresamente su
sincronización. Los cambios se anotan en una cola y se envían en segundo plano
mediante la API directa de PrestaShop.

La integración también puede dar de alta un artículo que todavía no existe
en la tienda: familias, producto, combinaciones de talla y color, precios e
imagen principal. Todo producto creado por Factuzam comienza **inactivo** en
PrestaShop. Solo puede activarse al final de un alta o una sincronización
correctas si el perfil lo autoriza expresamente, o después de forma manual.

> **Regla de publicación:** marcar **En web** en Factuzam hace que el artículo
> sea elegible para la integración configurada. Con **Activar artículos en
> PrestaShop al marcar En web** desmarcado, no cambia su visibilidad. Con el
> check marcado, Factuzam solicita la activación únicamente como último paso,
> después de completar correctamente el alta o la sincronización autorizada.

> **Regla al quitar En web:** Factuzam pregunta qué hacer. **Sí** desactiva el
> producto en PrestaShop y deja de sincronizarlo; **No** solo detiene la
> sincronización y conserva su estado remoto; **Cancelar** no guarda el cambio.
> Ninguna opción borra el producto, cambia su precio ni envía stock cero.

---

## 1. Estado de la integración

Este capítulo se actualiza a medida que se completa la integración. Conviene
distinguir lo que ya está disponible de lo que todavía requiere implantación
y pruebas.

| Función | Estado |
|---------|--------|
| Configuración por usuario, grupo o `Todos` | Disponible |
| Marca **En web** en artículos | Disponible |
| Marca **En web** en almacenes | Disponible |
| Cola por cambios de precio o stock | Disponible |
| Reconciliación completa periódica opcional | Disponible; desmarcada de forma predeterminada |
| Actualización del precio y la cantidad de productos y SKU existentes | Disponible; requiere **Sincronizar stock y precios** |
| Localización del producto por `reference` exacta y única | Disponible |
| Incidencia inmediata ante `reference` ambigua | Disponible; no elige ni crea otro recurso |
| Opción **Crear artículos en PrestaShop al darlos de alta** | Disponible y desmarcada de forma predeterminada |
| Opción **Activar artículos en PrestaShop al marcar En web** | Disponible y desmarcada de forma predeterminada; actúa solo al final del proceso |
| Límite de niveles de familia para el alta | Configurable por ámbito; el valor inicial `0` conserva toda la jerarquía local |
| Alta de familias, atributos, producto, combinaciones e imagen principal | Implementada; pendiente de superar la batería funcional completa del laboratorio |
| Importación manual de pedidos | Disponible para laboratorio y un único destino controlado; la validación funcional y el aislamiento multitienda no están cerrados |
| Portes de pedidos como servicio `GASTOS_T` | Implementado con SKU `GASTOS_T`, IVA normal de la empresa y sin movimiento de stock |
| Sincronización con producción | Desactivada por defecto; ver [seguridad del stock](#11-seguridad-del-stock) |

La integración actualiza el catálogo remoto, pero no importa automáticamente
en Factuzam los cambios hechos a mano en las fichas de PrestaShop. Debe
decidirse qué sistema es responsable de cada dato antes de activarla.

La opción **Ventas Mayor ▸ Pedidos ▸ Importar de PrestaShop** lee la URL y la
clave API efectivas de Parámetros del entorno. La ventana no tiene credenciales
propias ni muestra la clave. La empresa y el almacén se toman de la sesión. Si
se cambia la configuración con la ventana abierta, es obligatorio volver a
conectar y listar antes de importar.

Esta reutilización es todavía parcial: el importador no envía el **Id. tienda**
al consultar `orders`. Debe usarse una clave limitada a un solo destino y no se
considera apto para multitienda. El procedimiento, las columnas, la creación de
cliente y artículos, el servicio `GASTOS_T` y todos los límites operativos se
detallan en
[Ventas Mayor ▸ Pedidos ▸ Importar pedidos de PrestaShop](04-menu-ventas-mayor.md#importar-pedidos-de-prestashop).

> **Situación de validación:** no existe todavía una decisión **GO** para usar
> la integración completa en producción. Hay evidencia parcial del catálogo y
> de la cola en laboratorio, pero siguen pendientes la batería completa de
> pedidos, importación, concurrencia, servicio, barrido y ciclo hasta factura.
> Mantén desactivadas las escrituras de stock absoluto y realiza las pruebas
> únicamente contra una instalación controlada.

---

## 2. Visión general

```text
Cambio en artículo, tarifa o stock
               |
               v
      Cola de PrestaShop
               |
               +---- reference única ----> verifica; actualiza si se autoriza
               |
               +---- ninguna reference --> alta inicialmente inactiva, si se autoriza
               |
               `---- varias reference ---> ERROR inmediato, sin POST

Tras completar sin error el alta o la sincronización
               |
               `---- activación final, solo si N->S y el perfil la autoriza
```

Los checks son independientes. **Sincronizar stock y precios** autoriza las
modificaciones de productos existentes. **Crear artículos en PrestaShop al
darlos de alta** solicita actuar cuando falta el producto. **Activar artículos
en PrestaShop al marcar En web** permite cambiar `active` a `1` únicamente al
final del proceso iniciado por el paso de **En web** de No a Sí. Factuzam
valida el conjunto local antes del primer `POST` y todo producto nuevo se crea
con `active=0`. Una referencia ambigua siempre es una incidencia y nunca
provoca otra alta ni una activación.

Los eventos son el mecanismo principal. La recuperación de pendientes se
comprueba siempre cada 60 a 120 segundos, aunque **Hacer barrido
periódicamente** esté desmarcado. Este check habilita únicamente una
reconciliación completa, cada cierto número de horas, para detectar un cambio
que no hubiera llegado a la cola por una incidencia o una importación antigua.

Una fila de la cola representa el **artículo completo**. Si cambia el precio
de un SKU, Factuzam vuelve a calcular el artículo y todas sus combinaciones,
pero solo envía una modificación para los recursos cuyo valor remoto sea
distinto.

---

## 3. Configuración por ámbito

La configuración se encuentra en **Otros ▸ Parámetros del entorno**, dentro
de **PrestaShop**. Se guarda como los demás parámetros: puede definirse para
un usuario, para un grupo o para `Todos`. El valor efectivo se obtiene en este
orden:

1. Valor específico del usuario.
2. Valor de su grupo, si el usuario no lo ha definido.
3. Valor de `Todos`, si tampoco hay un valor de grupo.

Un perfil más específico sustituye al general. Así, dos empresas pueden usar
usuarios o grupos con empresas, tarifas, almacenes y tiendas PrestaShop
diferentes. Cada sesión procesa únicamente su configuración efectiva; no
recorre las configuraciones de los demás perfiles.

| Parámetro | Uso |
|-----------|-----|
| **Sincronizar stock y precios** | Autoriza al trabajador a actualizar los productos existentes localizados por `reference` única. También autoriza la escritura de cantidades absolutas. Valor inicial: desmarcado. |
| **Crear artículos en PrestaShop al darlos de alta** | Solicita el alta completa e inactiva cuando no haya correspondencia. Es independiente del check de sincronización y comienza desmarcado. |
| **Activar artículos en PrestaShop al marcar En web** | Su clave técnica es `appPrestaShopActivarArticulosAlMarcarWeb`. Se hereda por usuario, grupo o `Todos` y su valor inicial es `False` (desmarcado). Cuando **En web** pasa de No a Sí, autoriza `active=1` solo como último paso de un alta o una sincronización correctas. No cambia la regla de que el producto se crea primero con `active=0`. |
| **Hacer barrido periódicamente** | Habilita la reconciliación completa del catálogo cada cierto número de horas. Su clave técnica es `appPrestaShopHacerBarridoPeriodico`, se hereda por usuario, grupo o `Todos` y su valor inicial es `False` (desmarcado). No desactiva la recuperación de pendientes cada 60–120 segundos. |
| **URL** | URL base de la API, terminada normalmente en `/api`. Comienza vacía y debe configurarse expresamente en el ámbito correcto. |
| **Clave API** | Credencial del Webservice. Solo debe verla el administrador raíz y no debe copiarse a mensajes o registros. |
| **Tarifa** | Está en **Otros ▸ Parámetros del entorno ▸ PrestaShop**, corresponde a la clave `appPrestaShopTarifa` y su valor inicial es `PVP`. Se hereda por usuario, grupo o `Todos`. La tarifa efectiva proporciona el precio del producto padre y de cada SKU; a partir de ellos se calculan los impactos de las combinaciones. |
| **Reglas fiscales PrestaShop** | Identificadores remotos para IVA normal, reducido, superreducido y exento. Los valores iniciales 1, 2, 3 y 0 corresponden al laboratorio local y deben revisarse en cada tienda antes de permitir altas. Si no hay correspondencia válida, no se crea el producto. |
| **Empresa** | Empresa empleada para resolver el IVA, obtener el precio sin impuestos y seleccionar sus almacenes web. |
| **Id. tienda** | Identificador de la tienda dentro de PrestaShop. |
| **Id. idioma** | Idioma en el que se crean nombres, descripciones, categorías y atributos. El valor inicial del laboratorio es 1. |
| **Id. categoría raíz** | Categoría remota bajo la que se crea la primera familia local. Debe ser mayor que cero; el laboratorio usa 2 (`Home`). |
| **Niveles de familia a crear (0 = todos)** | Su clave técnica es `appPrestaShopNivelesFamiliaAlta`. Es un entero heredable por usuario, grupo o `Todos`; valor inicial: `0`. `0` conserva toda la jerarquía local y un valor mayor que cero conserva ese número de niveles contados desde la familia hoja. El subconjunto siempre se crea en orden raíz → hoja. La categoría raíz de PrestaShop configurada no cuenta como nivel local. |
| **Intervalo de recuperación** | Espera de seguridad entre comprobaciones por posibles cuelgues o cierres. Admite de 60 a 120 segundos; valor inicial: 60. Los cambios normales despiertan al trabajador inmediatamente. |
| **Horas entre barridos** | Intervalo entre reconciliaciones completas cuando **Hacer barrido periódicamente** está marcado. Valor inicial: 24 horas. |
| **Máximo de intentos** | Reintentos antes de dejar un trabajo en `ERROR`. Valor inicial: 10. |

Los dos checks que autorizan el mantenimiento del catálogo nacen desmarcados
y se pueden combinar así. **Activar artículos en PrestaShop al marcar En web**
y **Hacer barrido periódicamente** también nacen desmarcados, pero no cambian
esta matriz: el primero decide la visibilidad al final de un proceso y el
segundo cuándo buscar divergencias completas.

| Sincronizar | Crear | Producto existente | `reference` inexistente |
|-------------|-------|---------------------|--------------------------|
| No | No | No se envían cambios. | No se intenta crear. |
| Sí | No | Se actualizan precio y stock. | Incidencia: creación no autorizada. |
| No | Sí | Se localiza, pero no se modifica. | Se crea completo con `active=0`, sin sincronizar stock. |
| Sí | Sí | Se actualizan precio y stock. | Se crea con `active=0` y después sincroniza lo autorizado. |

Si el cambio **En web** fue de No a Sí y el check de activación está marcado,
la petición `active=1` se añade después de completar correctamente la acción
indicada en la matriz. Si hay un error anterior, el producto no se activa. Con
el check desmarcado, un producto nuevo permanece inactivo y un producto ya
existente conserva su visibilidad.

Antes de marcar **Sincronizar stock y precios**, hay que configurar y comprobar
expresamente la URL. Una instalación nueva no presupone ningún destino.

Las antiguas claves `appPrestaShopActivo` y `appPrestaShopStockActivo`, si
permanecen guardadas tras actualizar una instalación, ya no gobiernan el
trabajador ni activan nada de forma implícita. Deben usarse los controles
explícitos descritos en la tabla anterior.

Si varios perfiles compatibles comparten la misma instalación y tienda pero
solicitan intervalos de barrido distintos, se aplica materialmente la cadencia
más frecuente. Todos comparten el mismo marcador remoto para evitar recorridos
duplicados del catálogo.

La cola separa cada destino por la URL normalizada y el identificador de
tienda. Si se cambia de una tienda de pruebas a producción, no se reutilizan
los identificadores remotos de la instalación anterior. Para dos empresas con
tiendas distintas deben configurarse destinos distintos.

Varios perfiles activos pueden compartir la misma URL normalizada e Id. de
tienda cuando su empresa, tarifa y opciones de sincronización son idénticas.
Cada perfil puede decidir si participa en el barrido periódico. Si el
trabajador detecta que alguno de los datos funcionales es distinto, considera
el destino
contradictorio, detiene su procesamiento y registra un aviso. No se reanuda
hasta corregir los perfiles para que sean compatibles o asignarles destinos
diferentes.

### Permisos de la clave API

La clave debe tener solo los permisos necesarios:

| Recurso | Lectura | Alta | Modificación |
|---------|---------|------|--------------|
| `products` | Sí | Sí, si se autoriza el alta | Sí |
| `combinations` | Sí | Sí, si se autoriza el alta | Sí |
| `categories` | Sí | Sí, si se autoriza el alta | No |
| `product_options` | Sí | Sí, si se autoriza el alta | No |
| `product_option_values` | Sí | Sí, si se autoriza el alta | No |
| `images` | Sí | Sí, si se autoriza el alta | No |
| `stock_availables` | Sí | No | Sí, con **Sincronizar stock y precios** |
| `languages`, `shops`, `shop_groups` y reglas de IVA | Sí | No | No |
| `orders`, `customers`, `addresses` y `states` | Sí, si se importan pedidos | No | No |
| `carriers` y `order_states` | Sí, si se importan pedidos | No | No |
| `customer_threads` y `customer_messages` | Sí, si se importan pedidos y mensajes | No | No |

Los permisos de pedidos son solo de lectura. Si esa función no se utiliza, no
deben concederse. La clave destinada al importador debe quedar limitada a una
única tienda mientras la consulta de `orders` no aplique `id_shop`.

No debe concederse permiso de borrado salvo que se diseñe y autorice una
operación administrativa concreta. Una recuperación automática nunca debe
borrar una categoría, talla o color compartidos con otros productos.

---

## 4. Selección de artículos y almacenes

### Artículos

En **Archivo ▸ Artículos**, la casilla **En web** decide si el artículo
participa en la integración.

- Al marcarla, se encola una comprobación completa del artículo.
- Factuzam busca el producto maestro por coincidencia exacta de su
  `reference`.
- Si existe una sola coincidencia, lo verifica y solo actualiza el producto y
  sus SKU cuando está marcado **Sincronizar stock y precios**.
- Si no existe ninguna y está autorizado **Crear artículos**, valida y
  ejecuta el alta completa e inactiva.
- Si no está autorizada la creación, la ausencia termina en una incidencia.
- Si existen varias coincidencias, registra una incidencia `ERROR` sin elegir
  ninguna ni crear una tercera.
- Si la marca pasa de No a Sí y está autorizado **Activar artículos en
  PrestaShop al marcar En web**, la activación se solicita solo después de que
  termine correctamente el alta o la sincronización aplicable.
- Al desmarcarla, Factuzam muestra un diálogo antes de guardar.

Cambiar **En web** requiere el permiso **Permisos ▸ Artículos ▸
Activar/desactivar web**. Sin ese permiso la casilla queda en solo lectura y
la grabación tampoco puede alterar la marca.

Al quitar **En web**, el diálogo ofrece tres decisiones:

- **Sí**: guarda **En web = No**, deja de sincronizar y solicita la
  desactivación remota (`active=0`).
- **No**: guarda **En web = No** y solo deja de sincronizar. El producto
  permanece en el estado de visibilidad que ya tuviera en PrestaShop.
- **Cancelar**: no guarda el cambio; el artículo continúa **En web**.

En los dos primeros casos se cancelan los cambios pendientes de precio y
stock. La retirada no realiza otras modificaciones:

- no se envía stock cero;
- no se cambia el último precio enviado;
- no se elimina el producto;
- no se eliminan combinaciones, categorías o imágenes.

Si se vuelve a marcar **En web**, Factuzam encola una comprobación completa.
El precio y el stock vigentes solo se envían cuando el perfil efectivo tiene
marcado **Sincronizar stock y precios**. La activación final solo se solicita
cuando también está marcado **Activar artículos en PrestaShop al marcar En
web**.

Un SKU de un artículo web no se borra físicamente: se marca inactivo en
Factuzam para conservar su referencia. La integración deja de enviar su
precio y, con la sincronización habilitada, envía cantidad cero. PrestaShop
no ofrece un campo `active` propio en la combinación, por lo que esta
operación no «desactiva» remotamente el SKU ni lo elimina.

### Almacenes

En **Archivo ▸ Almacenes**, la casilla **En web** selecciona los almacenes
cuyo stock se suma para la tienda online. Puede marcarse uno solo o varios,
pero cada perfil utiliza únicamente los que pertenecen a su empresa
configurada. Un almacén marcado de otra empresa no participa en ese destino.

Además de la marca, el almacén debe ser:

- activo;
- físico;
- de tipo de uso **ESTANDAR**.

Los almacenes de **taras**, depósitos y otros usos no estándar quedan fuera
aunque alguien intente marcarlos. Las altas de almacenes comienzan con la
casilla desmarcada.

Al marcar o desmarcar un almacén se encolan los artículos afectados para
recalcular el total web. No es necesario recorrerlos manualmente desde la
pantalla.

---

## 5. Cola, eventos, recuperación y barrido opcional

Los cambios de precios y de stock en los principales procesos de Factuzam
llaman al encolador dentro de la misma unidad de trabajo siempre que es
posible. Varias llamadas para el mismo artículo se agrupan en una sola fila.
Cuando la operación queda confirmada, el propio proceso que generó el
pendiente despierta al consumidor. La señal es acumulativa: cien cambios de
un lote provocan un único vaciado de la cola, no cien ciclos independientes.
Estas señales no reinician ni aplazan la fecha límite monotónica de la
recuperación. Aunque lleguen cambios continuamente, el turno de seguridad
sigue venciendo cada 60–120 segundos y no puede quedar bloqueado por actividad
normal de la cola.

| Estado | Significado |
|--------|-------------|
| `PENDIENTE` | Hay una versión por enviar o verificar. |
| `PROCESANDO` | Un trabajador ha reclamado temporalmente el artículo. |
| `PENDIENTE_VISIBILIDAD` | Hay una activación o desactivación explícita pendiente. Puede coexistir con cambios de precio o stock. |
| `PROCESANDO_VISIBILIDAD` | Un trabajador ha reclamado temporalmente una activación o desactivación. |
| `ENVIADA` | La versión reclamada quedó verificada en PrestaShop. |
| `ERROR` | Se agotaron los intentos o existe una incidencia terminal que requiere revisión. Una `reference` ambigua llega aquí inmediatamente; una inexistente también lo hace si el alta automática está desactivada o no cumple sus requisitos. |

Si el artículo cambia mientras se está enviando, el cambio nuevo incrementa
su versión pero no libera la reclamación en curso. Al terminar el envío
anterior, la fila vuelve a `PENDIENTE`. Así se evita que dos trabajadores
escriban versiones antiguas y nuevas en orden inverso.

Al quitar **En web** y elegir **No**, el mismo control de versión deja vacíos
los dos indicadores de cambio. Si se elige **Sí**, además queda solicitada la
desactivación remota. Una petición que ya estuviera en curso puede terminar;
después se aplica, cuando corresponda, la decisión de visibilidad y no se
reclaman nuevas versiones de precio o stock. **Cancelar** no guarda el cambio
ni altera la cola.

Cada 60 a 120 segundos se realiza siempre una comprobación de recuperación por
si un proceso se cerró después de encolar o quedó una reclamación interrumpida.
La base de datos concede esa comprobación a una sola instancia de Factuzam por
destino. El proceso ganador recupera reclamaciones caducadas y vacía los
pendientes; los demás no repiten el trabajo. Desmarcar **Hacer barrido
periódicamente** no desactiva este mecanismo. Las señales recibidas entre dos
turnos tampoco desplazan su próximo vencimiento.

Cuando **Hacer barrido periódicamente** está marcado y han transcurrido las
horas configuradas, una única sesión habilitada ejecuta la reconciliación
completa y encola de nuevo los artículos **En web** que lo necesiten. Este
arbitraje es independiente del ganador de la recuperación, para que un perfil
con el check desmarcado no impida el barrido solicitado por otro perfil
compatible. Con el check desmarcado no recorre todo el catálogo, pero sigue
rescatando y procesando la cola cada 60–120 segundos. Un fallo de la
reconciliación completa tampoco impide que se sigan procesando los eventos.

Cada sesión reclama solamente la cola del destino que resulta de su perfil
efectivo. Los destinos quedan aislados por URL normalizada e identificador de
tienda.

Antes de vaciar la cola, el trabajador vuelve a leer de la base de datos el
perfil efectivo con la herencia usuario → grupo → `Todos`. Por tanto, un cambio
o una desactivación guardados en el usuario, su grupo o `Todos` llegan a los
terminales que ya están abiertos sin reiniciar la aplicación.

### Ventana de seguimiento

La cola puede revisarse en **Otros ▸ Colas de envíos ▸ PrestaShop**. La
lista muestra la tienda, el código y nombre del artículo, los indicadores de
precio y stock pendiente o reclamado, el estado, los intentos, las fechas de
próximo intento, último cambio y último envío, y el error general de la
fila.

Al seleccionar una fila se muestra su historial de operaciones HTTP, con
intento, orden, método, recurso relativo, código y texto de estado HTTP,
resultado, instante de inicio y duración. Al seleccionar una operación se
cargan, bajo demanda, sus pestañas **Petición**, **Respuesta del servidor** y
**Error**. De esta forma, los cuerpos extensos no se leen al abrir o recorrer
la lista principal.

El historial empieza a conservarse desde la instalación de esta versión. Las
operaciones realizadas anteriormente no se reconstruyen de forma retroactiva.

El historial es de diagnóstico. No guarda la clave API, cabeceras de
autorización, contenido binario, datos en base64 ni rutas locales completas.
En una subida de imagen conserva solo una descripción segura, como el nombre,
el tamaño y la huella. Los textos que exceden el límite de almacenamiento se
recortan con una marca visible de truncado.

La ventana es de **solo lectura** y no permite editar, borrar ni reintentar
una fila. Solo ofrece actualizar la consulta, exportarla cuando exista el
permiso e ir al artículo relacionado. Los permisos separados **Consultar**,
**Excel** y **Ver petición/respuesta** controlan el acceso a la lista, la
exportación y el detalle respectivamente. Un administrador puede consultar
todos los destinos; los demás usuarios ven exclusivamente la tienda resuelta
por su configuración efectiva.

La rejilla muestra el **Id. tienda**, pero no una etiqueta de instalación. Si
se supervisan varias instalaciones que reutilizan el mismo identificador de
tienda, ese dato por sí solo no permite distinguirlas; contrasta el destino
efectivo antes de interpretar o exportar la fila.

### Cierre de Factuzam durante un envío

Si se intenta cerrar Factuzam mientras esta instancia está procesando un
artículo, primero se bloquean nuevas reclamaciones y se ofrecen tres opciones:

- **Esperar**: termina únicamente el artículo actual y después cierra.
- **Cerrar de todos modos**: no interrumpe a mitad la petición HTTP que ya está
  en curso. Espera su retorno, devuelve el artículo a pendiente sin consumir un
  intento y después cierra.
- **Cancelar cierre**: mantiene Factuzam abierto, desbloquea las reclamaciones
  y reanuda el consumo de la cola.

El cierre forzado puede tardar hasta que termine la operación de red actual. La
fila liberada conserva sus cambios de precio, stock o visibilidad y podrá ser
reclamada por esta u otra instancia en el siguiente ciclo.

---

## 6. Precios de producto y de SKU

PrestaShop guarda los precios sin impuestos:

- `products.price` es el precio base del producto;
- `combinations.price` es el **impacto** de la combinación sobre la base;
- el precio efectivo de un SKU es la suma de ambos.

Factuzam obtiene el precio final vigente de la tarifa y la empresa del perfil
efectivo. Si la tarifa incluye IVA, lo divide por
`1 + tipo de IVA / 100` antes de enviarlo.
En los productos que ya existen, la integración actual no cambia ni valida
`id_tax_rules_group`: el administrador debe comprobar que la regla fiscal
remota sea correcta. En el alta se usa el identificador configurado para el
tipo de IVA local; no basta con que ambos sistemas muestren el mismo
porcentaje.

Ejemplo con IVA del 21 %:

| Concepto | Precio con IVA | Precio sin IVA enviado |
|----------|----------------|-------------------------|
| Producto base | 31,95 | 26,404959 |
| SKU con precio propio | 29,95 | 24,752066 |
| Impacto de la combinación | — | -1,652893 |

No debe enviarse `29,95` directamente como `combinations.price`, porque
PrestaShop lo sumaría otra vez al precio base.

Cuando cambia únicamente un SKU, en PrestaShop 9 se puede modificar solo su
combinación. Factuzam, aun así, recalcula y verifica todas las combinaciones
del artículo. Si cambia el precio base, recalcula todos los impactos para
que los precios efectivos de los demás SKU permanezcan correctos.

Este comportamiento se verificó en la tienda local PrestaShop 9.1.4 con un
producto de tres combinaciones. Al modificar únicamente un impacto, el precio
base y las otras dos combinaciones conservaron sus valores. La prueba confirmó
también que `combinations.price` es un impacto y no el precio final del SKU.

---

## 7. Alta de un artículo inexistente

El check **Crear artículos en PrestaShop al darlos de alta** está disponible,
comienza desmarcado y es independiente de **Sincronizar stock y precios**.
Una `reference` inexistente inicia el alta solo cuando este check está
marcado. Una referencia ambigua termina en `ERROR` y nunca provoca un alta.

El alta no es una sola petición. El trabajador ejecuta esta secuencia contra
varios recursos de PrestaShop:

1. Validar todos los datos locales sin crear nada todavía.
2. Resolver o crear la ruta de categorías de la familia bajo la raíz
   configurada.
3. Resolver o crear los grupos de atributos, como **Color** y **Talla**.
4. Resolver o crear los valores utilizados por los SKU.
5. Crear el producto maestro con `active=0`.
6. Crear una combinación por cada SKU activo y elegir una sola combinación
   predeterminada de forma determinista.
7. Subir una fotografía general real si el producto todavía no tiene ninguna.
8. Continuar con la sincronización de precio y stock solo si está autorizada.
9. Si el proceso procede de marcar **En web** y el perfil lo autoriza, activar
   el producto únicamente después de que todos los pasos anteriores terminen
   correctamente.

El producto se crea siempre **completo e inicialmente inactivo**. Con
`appPrestaShopActivarArticulosAlMarcarWeb=False`, permanece así hasta la
revisión manual. Con el parámetro a `True`, el mismo trabajo puede activarlo
como último paso. Un alta parcial o una sincronización con error nunca debe
dejar visible el producto.

### Validación previa

Antes del primer `POST` deben comprobarse, al menos:

- código de artículo y referencias de SKU no vacíos ni duplicados;
- artículo, familia, tarifa y atributos activos;
- jerarquía de familias completa y sin ciclos;
- nombre y descripción válidos para los límites de PrestaShop;
- precio base vigente y precio efectivo de cada SKU;
- correspondencia del IVA con un grupo fiscal remoto;
- un valor válido por cada eje de variación necesario;
- fotografía real registrada, existente y legible;
- ausencia inequívoca del producto y de sus referencias en PrestaShop.

Si falta un requisito el artículo queda en `ERROR` con una causa concreta y
la validación local evita comenzar el alta.

### Revisión del administrador

El administrador entra en el back office de PrestaShop y comprueba:

1. Nombre, descripción y categoría.
2. Tipo y regla de IVA.
3. Tallas, colores y combinación predeterminada.
4. Precio final de varias combinaciones, incluidas las de impacto negativo.
5. Fotografía de portada e imágenes por color.
6. Política de stock y disponibilidad para pedidos.

Solo entonces activa las categorías nuevas necesarias. Si la activación
automática está desmarcada, activa también el producto manualmente. Si está
marcada, comprueba que el trabajo terminó sin error y que el producto solo se
hizo visible al final.

---

## 8. Familias y categorías

En el alta, la familia de Factuzam se transforma en una categoría de
PrestaShop. El parámetro heredable **Niveles de familia a crear (0 = todos)**
(`appPrestaShopNivelesFamiliaAlta`) determina qué parte de la jerarquía local
se exporta:

- `0`: toda la jerarquía local, desde su raíz hasta la familia hoja;
- `N > 0`: los últimos `N` niveles, contados desde la familia hoja hacia
  arriba.

El subconjunto elegido se conserva y crea en orden raíz → hoja: los padres
van antes que sus hijos. La categoría raíz configurada en PrestaShop es solo
el punto remoto bajo el que se cuelga el subconjunto y **no cuenta** como uno
de esos niveles. Por ejemplo, **DEMO-CAMISA** pertenece únicamente a la
familia local **ROPA**; por tanto, `0`, `1` o cualquier valor superior solo
exportan ese nivel local.

Una categoría ya existente conserva su estado. En la implementación actual
las categorías nuevas se crean activas. El producto se crea con `active=0` y
solo puede activarse después, como último paso, según el parámetro de
activación.

La identidad no puede basarse solo en el nombre. Dos ramas pueden contener
una categoría llamada igual. La implementación busca la combinación de padre
y enlace normalizado antes de crear:

```text
tienda + categoría padre + enlace normalizado -> id_category remoto
```

El producto usa la familia hoja como `id_category_default` y también la
incluye entre sus asociaciones de categorías. La categoría raíz bajo la que
se exportan las familias debe ser configurable en cada tienda.

---

## 9. Tallas, colores y combinaciones

Los atributos locales de una variación se convierten así:

| Factuzam | PrestaShop |
|----------|------------|
| Tipo o eje **Talla** | `product_option`, tipo `select` |
| Valor **M**, **L**, **44**… | `product_option_value` |
| Tipo o eje **Color** | `product_option`, tipo `color` |
| Valor **Negro**, **Azul**… | `product_option_value`, con color hexadecimal cuando exista |
| SKU | `combination` |

Cada combinación conservará como `reference` el código exacto del SKU local y
asociará todos sus valores, por ejemplo **Color: Azul** y **Talla: L**. Solo
se crearán SKU activos. Después se marcará como predeterminada una única
combinación: la primera según el orden estable de atributos y referencia.

Las tallas y los colores son recursos compartidos. Antes de crear se busca el
grupo o valor remoto correspondiente. Si existen varias coincidencias y no
puede saberse cuál es la correcta, el alta se detiene para revisión en lugar
de escoger una al azar.

---

## 10. Fotografías reales

Factuzam registra las fotos por artículo, por prefijo de SKU —habitualmente
el color— o por SKU completo. La integración usa la resolución **real**:

```text
<appDirFotos>\real\<nombre registrado>.png
```

La extensión de origen guardada en la base de datos es informativa. El
fichero operativo que genera Factuzam es PNG.

En la implementación actual se elige la fotografía general principal y se
sube únicamente cuando el producto remoto no tiene ninguna imagen. PrestaShop
genera automáticamente los tamaños derivados. Las galerías, la sustitución de
una foto ya subida y la asociación de fotos por color quedan fuera del flujo
actual y deben hacerse manualmente.

> En una instalación donde `fza_articulos_fotos` esté vacía, la existencia
> de ficheros sueltos en la carpeta no basta. Primero deben relacionarse las
> fotos con sus artículos o SKU. No se adivina esa relación por el nombre del
> fichero.

---

## 11. Seguridad del stock

El stock web se calcula sumando solo los almacenes elegibles y limitando el
resultado mínimo a cero. El almacén de taras nunca participa.

Sin embargo, el Webservice estándar de PrestaShop recibe una cantidad
absoluta. Si una venta web todavía no está reservada automáticamente en
Factuzam, un movimiento local posterior podría volver a escribir una
cantidad que reponga unidades ya vendidas.

Por este motivo:

- **Sincronizar stock y precios** permanece desmarcado de forma
  predeterminada;
- el check vigente autoriza conjuntamente el precio y el stock: no existe una
  autorización separada del stock en el trabajador actual;
- no debe marcarse en producción hasta disponer de ingestión o reserva
  automática de pedidos web y pruebas completas de concurrencia;
- los servicios, taras, depósitos y almacenes no estándar quedan excluidos.

El stock compartido entre tiendas tampoco está soportado actualmente. El
cliente exige una fila `stock_available` perteneciente exactamente a la
tienda configurada y falla de forma segura si PrestaShop usa `id_shop=0` con
un grupo de tiendas. Ese modo necesitará validar antes `share_stock` y el
grupo efectivo.

Esta cautela no impide el alta de familias, producto, combinaciones, precios
o imagen principal. Con la sincronización desmarcada, el producto nuevo queda
preparado e inactivo sin publicar el stock local.

---

## 12. Reintentos y prevención de duplicados

La API no ofrece una transacción única para crear todo el catálogo. El alta
se trata como una secuencia reanudable:

```text
VALIDAR -> CATEGORIAS -> ATRIBUTOS -> PRODUCTO_INACTIVO
        -> SKU -> IMAGEN_PRINCIPAL -> SINCRONIZACION_AUTORIZADA
        -> ACTIVACION_FINAL_OPCIONAL
```

Antes de cada alta se busca el recurso remoto por su identidad. Si se corta
la red, el siguiente intento vuelve a buscar y reutiliza lo que ya exista. La
batería funcional debe verificar esta idempotencia, especialmente con dos
trabajadores concurrentes, porque la búsqueda y el `POST` no forman una
transacción única.

Reglas de seguridad:

- una referencia ambigua nunca provoca un alta nueva;
- producto y SKU se resuelven por referencia exacta y relación padre;
- categorías y atributos se buscan dentro de su padre o grupo;
- una imagen no se vuelve a subir si el producto ya tiene alguna;
- un fallo nunca activa el producto;
- los recursos compartidos no se borran como compensación automática.

---

## 13. Diagnóstico de incidencias

| Incidencia | Comprobación |
|------------|-------------|
| **401 / 403** | Revisar clave API y permisos; no copiar la clave en el parte de soporte. |
| **Producto no encontrado** | Si la creación está desmarcada, se registra `ERROR` inmediato. Si está marcada, revisar los requisitos locales y los permisos POST del Webservice. |
| **Referencia ambigua** | Se registra `ERROR` inmediato. Corregir duplicados en PrestaShop; Factuzam no elige uno ni crea otro automáticamente. |
| **Categoría o talla duplicada** | Revisar el mapeo de instalación y tienda, no solo el nombre visible. |
| **Precio de SKU demasiado alto** | Comprobar que se envía un impacto y no el precio final como `combinations.price`. |
| **Foto no encontrada** | Revisar `appDirFotos`, la fila de `fza_articulos_fotos` y el PNG de `real`. |
| **Almacén no incluido** | Debe estar En web, activo, físico y ser de uso ESTANDAR. |
| **Artículo nuevo no aparece en la página** | El alta siempre comienza con `active=0`. Revisar si **Activar artículos en PrestaShop al marcar En web** está desmarcado, si el trabajo terminó sin error o si la activación final quedó pendiente. Con el check desmarcado debe activarse manualmente tras la revisión. |
| **Artículo desmarcado sigue visible** | Si se eligió **No**, es el comportamiento solicitado: solo deja de sincronizarse. Para retirarlo, volver a marcarlo y desmarcarlo eligiendo **Sí**, o desactivarlo manualmente en PrestaShop. |
| **Cancelé al quitar En web** | No se guarda el cambio, no se desactiva el producto y no se modifica la cola. |
| **Se crean demasiados niveles de categoría** | Revisar **Niveles de familia a crear (0 = todos)**. Los valores positivos se cuentan desde la hoja; la raíz PrestaShop configurada no cuenta. |
| **Fila en ERROR** | Corregir la causa y reencolar. El reintento busca y reutiliza los recursos ya creados; comprobar que no haya duplicados. |
| **Desmarqué el barrido y se procesó un pendiente** | Es correcto: el check solo desactiva la reconciliación completa por horas. La recuperación de filas pendientes y reclamaciones interrumpidas continúa cada 60–120 segundos. |

Los mensajes de error y los registros nunca deben incluir la clave API.

---

## 14. Lista de comprobación para una implantación

1. Aplicar la migración de base de datos y comprobar las marcas **En web**.
2. Configurar primero una tienda de pruebas de la misma versión que la tienda
   real; no usar producción para la validación inicial.
3. Crear una clave API de mínimo privilegio. Si se importan pedidos, añadir
   solo lectura sobre `orders`, `customers`, `addresses`, `states`, `carriers`,
   `order_states`, `customer_threads` y `customer_messages`.
4. Configurar el ámbito correcto —usuario, grupo o `Todos`—, URL, tienda,
   empresa y tarifa con los cuatro checks desmarcados.
5. Mientras la importación no filtre por `id_shop`, usar una clave exclusiva
   para una sola tienda y no habilitar el flujo en una instalación multitienda.
6. Revisar **Niveles de familia a crear (0 = todos)**: usar `0` para toda la
   jerarquía local o un número positivo contado desde la familia hoja.
7. Marcar únicamente los almacenes estándar que aportarán stock web.
8. Revisar familias, IVA, SKU, atributos, precios y fotos reales.
9. Probar un artículo con varios colores, tallas y precios por SKU.
10. Confirmar que una `reference` ambigua deja un `ERROR` inmediato sin crear
   recursos.
11. Mantener **Crear artículos en PrestaShop al darlos de alta** desmarcado
   hasta superar la batería funcional del laboratorio.
12. Entrar con la empresa y el almacén correctos; importar en laboratorio un
    pedido con portes y otro sin ellos. Revisar cliente, productos, SKU, IVA,
    totales y la línea de servicio `GASTOS_T`.
13. Repetir el mismo `ID PS`, provocar un error intermedio y comprobar que no
    se duplica el pedido y que los siguientes seleccionados continúan. No
    ejecutar dos importaciones concurrentes del mismo pedido.
14. Servir el pedido de prueba hasta albarán y factura: `GASTOS_T` debe
    conservar el tipo **SERVICIO**, base e IVA sin mover stock; las líneas
    físicas sí deben moverlo.
15. Probar las opciones de cierre **Esperar**, **Cerrar de todos modos** y
    **Cancelar cierre** con un envío real controlado.
16. Comprobar una ingestión o reserva automática de pedidos web, distinta de
    la importación manual, antes de autorizar cantidades absolutas.
17. Mantener **Sincronizar stock y precios** desmarcado mientras no exista una
    decisión GO documentada para la batería completa.
18. Con la activación automática desmarcada, repetir el alta para comprobar
    que conserva IDs, no duplica recursos y deja el producto completo pero
    inactivo.
19. En el laboratorio, marcar **Activar artículos en PrestaShop al marcar En
    web** y comprobar que `active=1` se solicita solo al final de un proceso
    correcto; provocar un error previo y confirmar que no se activa.
20. Probar las tres respuestas al quitar **En web**: **Sí** desactiva, **No**
    solo deja de sincronizar y **Cancelar** no guarda.

Las pruebas de desarrollo se realizan únicamente contra la instalación local
actual de PrestaShop. No se hacen altas ni modificaciones de prueba en la
tienda de producción.

---

## 15. Referencias técnicas oficiales

- [Creación completa de un producto con Webservice](https://devdocs.prestashop-project.org/9/webservice/tutorials/create-product-az/)
- [Recurso `products`](https://devdocs.prestashop-project.org/9/webservice/resources/products/)
- [Recurso `combinations`](https://devdocs.prestashop-project.org/9/webservice/resources/combinations/)
- [Grupos de atributos](https://devdocs.prestashop-project.org/9/webservice/resources/product_options/)
- [Valores de atributos](https://devdocs.prestashop-project.org/9/webservice/resources/product_option_values/)
- [Gestión de imágenes](https://devdocs.prestashop-project.org/9/webservice/tutorials/advanced-use/image-management/)

---

[◀ Arquitectura y desarrollo](14-arquitectura-y-desarrollo.md) · [Índice](README.md)
