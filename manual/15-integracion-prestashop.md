# 15 · Integración con PrestaShop

[◀ Volver al índice](README.md)

La integración con **PrestaShop** permite que Factuzam sea el origen de los
precios y del stock de la tienda online cuando se autoriza expresamente su
sincronización. Los cambios se anotan en una cola y se envían en segundo plano
mediante la API directa de PrestaShop.

La integración también puede dar de alta un artículo que todavía no existe
en la tienda: familias, producto, combinaciones de talla y color, precios e
imagen principal. Todo producto creado por Factuzam queda **inactivo** en
PrestaShop hasta que un administrador lo revise y lo publique manualmente.

> **Regla de publicación:** marcar **En web** en Factuzam hace que el artículo
> sea elegible para la integración configurada. No significa «hacer visible en
> la tienda». Las acciones dependen de los checks del perfil y Factuzam nunca
> activa automáticamente un producto nuevo ni cambia posteriormente su estado
> `active`.

> **Regla al quitar En web:** se detiene la sincronización de **precios y
> stock**. No se desactiva ni borra el producto remoto, no se cambia su precio
> y no se envía stock cero. PrestaShop conserva exactamente su último estado.

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
| Alta de familias, atributos, producto, combinaciones e imagen principal | Implementada; pendiente de superar la batería funcional completa del laboratorio |
| Sincronización con producción | Desactivada por defecto; ver [seguridad del stock](#11-seguridad-del-stock) |

La integración actualiza el catálogo remoto, pero no importa automáticamente
en Factuzam los cambios hechos a mano en las fichas de PrestaShop. Debe
decidirse qué sistema es responsable de cada dato antes de activarla.

La opción **Ventas Mayor ▸ Pedidos ▸ Importar de PrestaShop** usa esa misma
configuración efectiva de Parámetros de Entorno. La ventana de importación no
tiene una URL ni una clave API propias y nunca muestra la credencial. Si se
cambia la configuración con la ventana abierta, es obligatorio volver a
conectar y listar antes de importar.

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
               +---- ninguna reference --> alta inactiva, si se autoriza
               |
               `---- varias reference ---> ERROR inmediato, sin POST
```

Los checks son independientes. **Sincronizar stock y precios** autoriza las
modificaciones de productos existentes. **Crear artículos en PrestaShop al
darlos de alta** solicita actuar cuando falta el producto. Factuzam valida el
conjunto local antes del primer `POST` y crea el producto con `active=0`. Una
referencia ambigua siempre es una incidencia y nunca provoca otra alta.

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
| **Hacer barrido periódicamente** | Habilita la reconciliación completa del catálogo cada cierto número de horas. Su clave técnica es `appPrestaShopHacerBarridoPeriodico`, se hereda por usuario, grupo o `Todos` y su valor inicial es `False` (desmarcado). No desactiva la recuperación de pendientes cada 60–120 segundos. |
| **URL** | URL base de la API, terminada normalmente en `/api`. Comienza vacía y debe configurarse expresamente en el ámbito correcto. |
| **Clave API** | Credencial del Webservice. Solo debe verla el administrador raíz y no debe copiarse a mensajes o registros. |
| **Tarifa** | Está en **Otros ▸ Parámetros del entorno ▸ PrestaShop**, corresponde a la clave `appPrestaShopTarifa` y su valor inicial es `PVP`. Se hereda por usuario, grupo o `Todos`. La tarifa efectiva proporciona el precio del producto padre y de cada SKU; a partir de ellos se calculan los impactos de las combinaciones. |
| **Reglas fiscales PrestaShop** | Identificadores remotos para IVA normal, reducido, superreducido y exento. Los valores iniciales 1, 2, 3 y 0 corresponden al laboratorio local y deben revisarse en cada tienda antes de permitir altas. Si no hay correspondencia válida, no se crea el producto. |
| **Empresa** | Empresa empleada para resolver el IVA, obtener el precio sin impuestos y seleccionar sus almacenes web. |
| **Id. tienda** | Identificador de la tienda dentro de PrestaShop. |
| **Id. idioma** | Idioma en el que se crean nombres, descripciones, categorías y atributos. El valor inicial del laboratorio es 1. |
| **Id. categoría raíz** | Categoría remota bajo la que se crea la primera familia local. Debe ser mayor que cero; el laboratorio usa 2 (`Home`). |
| **Intervalo de recuperación** | Espera de seguridad entre comprobaciones por posibles cuelgues o cierres. Admite de 60 a 120 segundos; valor inicial: 60. Los cambios normales despiertan al trabajador inmediatamente. |
| **Horas entre barridos** | Intervalo entre reconciliaciones completas cuando **Hacer barrido periódicamente** está marcado. Valor inicial: 24 horas. |
| **Máximo de intentos** | Reintentos antes de dejar un trabajo en `ERROR`. Valor inicial: 10. |

Los dos checks que autorizan escrituras nacen desmarcados y se pueden combinar
así. **Hacer barrido periódicamente** también nace desmarcado, pero no cambia
esta matriz: decide cuándo buscar divergencias completas, no qué escrituras
están autorizadas.

| Sincronizar | Crear | Producto existente | `reference` inexistente |
|-------------|-------|---------------------|--------------------------|
| No | No | No se envían cambios. | No se intenta crear. |
| Sí | No | Se actualizan precio y stock. | Incidencia: creación no autorizada. |
| No | Sí | Se localiza, pero no se modifica. | Se crea completo e inactivo, sin sincronizar stock. |
| Sí | Sí | Se actualizan precio y stock. | Se crea inactivo y después sincroniza lo autorizado. |

Antes de marcar **Sincronizar stock y precios**, hay que configurar y comprobar
expresamente la URL. Una instalación nueva no presupone ningún destino.

Las antiguas claves `appPrestaShopActivo` y `appPrestaShopStockActivo`, si
permanecen guardadas tras actualizar una instalación, ya no gobiernan el
trabajador ni activan nada de forma implícita. Las autorizaciones vigentes son
los dos checks independientes descritos en la tabla anterior.

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
- Al desmarcarla, Factuzam cancela los cambios pendientes de precio y stock
  y deja de mantenerlo sincronizado.

Cambiar **En web** requiere el permiso **Permisos ▸ Artículos ▸
Activar/desactivar web**. Sin ese permiso la casilla queda en solo lectura y
la grabación tampoco puede alterar la marca.

Al quitar **En web**, no se realiza ninguna acción de retirada sobre
PrestaShop:

- no se envía stock cero;
- no se cambia el último precio enviado;
- no se desactiva ni elimina el producto;
- no se eliminan combinaciones, categorías o imágenes.

Si el administrador desea retirarlo de la página, debe desactivarlo
manualmente en PrestaShop. Si se vuelve a marcar **En web**, Factuzam encola
una comprobación completa. El precio y el stock vigentes solo se envían cuando
el perfil efectivo tiene marcado **Sincronizar stock y precios**.

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
| `ENVIADA` | La versión reclamada quedó verificada en PrestaShop. |
| `ERROR` | Se agotaron los intentos o existe una incidencia terminal que requiere revisión. Una `reference` inexistente o ambigua llega aquí inmediatamente. |

Si el artículo cambia mientras se está enviando, el cambio nuevo incrementa
su versión pero no libera la reclamación en curso. Al terminar el envío
anterior, la fila vuelve a `PENDIENTE`. Así se evita que dos trabajadores
escriban versiones antiguas y nuevas en orden inverso.

Quitar **En web** usa el mismo control de versión, pero deja vacíos los dos
indicadores de cambio. Una petición que ya estuviera en curso puede terminar;
después de ella no se reclaman ni envían nuevas versiones del artículo.

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

El resultado es **creado, completo e inactivo**. El servicio puede seguir
actualizando después precios y stock, pero no dispone de una operación para
cambiar `active`.

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

Solo entonces activa manualmente las categorías nuevas necesarias y el
producto. Factuzam respetará esa decisión y no modificará el estado de
publicación.

---

## 8. Familias y categorías

En el alta, la familia de Factuzam se transforma en una categoría de
PrestaShop. La jerarquía se recorre desde la familia raíz hasta la hoja del
artículo; los padres se crean antes que sus hijos. Una categoría ya existente
conserva su estado. En la implementación actual las categorías nuevas se
crean activas; el producto permanece inactivo, por lo que no aparece en el
escaparate hasta la revisión manual.

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
        -> SKU -> IMAGEN_PRINCIPAL
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
| **Artículo nuevo no aparece en la página** | Es el comportamiento previsto del alta: se crea con `active=0` y el administrador debe revisarlo y activarlo manualmente. |
| **Artículo desmarcado sigue visible** | Es el comportamiento previsto: quitar En web solo detiene precio y stock. Desactívelo manualmente en PrestaShop si desea retirarlo. |
| **Fila en ERROR** | Corregir la causa y reencolar. El reintento busca y reutiliza los recursos ya creados; comprobar que no haya duplicados. |
| **Desmarqué el barrido y se procesó un pendiente** | Es correcto: el check solo desactiva la reconciliación completa por horas. La recuperación de filas pendientes y reclamaciones interrumpidas continúa cada 60–120 segundos. |

Los mensajes de error y los registros nunca deben incluir la clave API.

---

## 14. Lista de comprobación para una implantación

1. Aplicar la migración de base de datos y comprobar las marcas **En web**.
2. Configurar primero una tienda de pruebas de la misma versión que la tienda
   real; no usar producción para la validación inicial.
3. Crear una clave API de mínimo privilegio.
4. Configurar el ámbito correcto —usuario, grupo o `Todos`—, URL, tienda,
   empresa y tarifa con los tres checks desmarcados.
5. Marcar únicamente los almacenes estándar que aportarán stock web.
6. Revisar familias, IVA, SKU, atributos, precios y fotos reales.
7. Probar un artículo con varios colores, tallas y precios por SKU.
8. Confirmar que una `reference` ambigua deja un `ERROR` inmediato sin crear
   recursos.
9. Mantener **Crear artículos en PrestaShop al darlos de alta** desmarcado
   hasta superar la batería funcional del laboratorio.
10. Comprobar la reserva o ingestión automática de pedidos web antes de
    autorizar cantidades absolutas.
11. Marcar **Sincronizar stock y precios** únicamente después de completar
    todas las comprobaciones.
12. Repetir el alta para confirmar que conserva IDs, no duplica recursos y
    deja el producto completo pero inactivo.

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
