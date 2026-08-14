# Puerta A — PrestaShop local

Fecha de la línea base: `2026-08-14 05:56:18 +02:00`.

## Aislamiento y arranque

- Procedimiento contrastado con `tmp/prestashop_factuzam_lab/LABORATORIO.md`.
- Configuración Apache validada con `Syntax OK`.
- Instancia iniciada en segundo plano, sin ventana visible.
- PID padre: `4764`; PID hijo: `15404`.
- El fichero `logs/httpd.pid` contiene `4764`.
- Única escucha de esta instancia: `127.0.0.1:8081`.
- Los procesos Apache de los puertos `80` y `443` pertenecen a la instalación
  principal y no se han modificado.
- La instancia queda arrancada para continuar las pruebas.

## PS-INS-05

Resultado: **PASA**.

- Portada: HTTP `200`; título `FactuZam PrestaShop Lab`.
- Back office: HTTP `200` después de la redirección al formulario de acceso.
- `/api` sin autenticación: HTTP `401`.
- `/api` con la clave del laboratorio: HTTP `200`.
- Base: `prestashop_factuzam_lab`.
- Prefijo: `pslab_`; `301` tablas con ese prefijo y ninguna con otro.
- Tienda: identificador `1`, nombre `FactuZam PrestaShop Lab`, activa y no
  eliminada.
- Dominio y dominio SSL: `127.0.0.1:8081`.
- No hay referencias a `martamere` ni `herreras` en la configuración
  comprobada.
- Versiones: PrestaShop `9.1.4`, MariaDB `12.3.2`, Apache `2.4.66` y PHP
  `8.5.5`.

## PS-INS-06, parte no mutante

Resultado: **PASA la lectura y la auditoría; quedan pendientes las escrituras
funcionales de las puertas posteriores**.

Permisos efectivos publicados por la propia API:

| Recurso | Métodos |
|---|---|
| `products` | `GET`, `PATCH` |
| `combinations` | `GET`, `PATCH` |
| `stock_availables` | `GET`, `PATCH` |
| `shops` | `GET` |

- Los cuatro `GET` reales devolvieron HTTP `200`.
- Recursos con permiso `DELETE`: `0`.
- No se ejecutó ningún `POST`, `PATCH`, `PUT` ni `DELETE`.
- No se modificaron permisos, configuración ni datos.

## Recuentos de línea base

| Recurso | Antes | Después de las lecturas |
|---|---:|---:|
| Productos | 19 | 19 |
| Combinaciones | 39 | 39 |
| Imágenes en BBDD | 23 | 23 |
| Clientes | 2 | 2 |
| Carros | 5 | 5 |
| Pedidos | 5 | 5 |

Árbol físico `www/img/p`:

- archivos totales: `885`;
- archivos de imagen: `884`;
- tamaño conjunto de imágenes: `11.427.116` bytes;
- SHA-256 del manifiesto ordenado de rutas, tamaños y huellas:
  `C2AAB74841186CB0A7B5AE8C11E05A076E5B11D23ED6B81DBD9FD45548FE7B32`.

La identidad de los recuentos antes y después confirma que esta parte de la
puerta fue de solo lectura.

## Ampliación controlada de PS-INS-06

Resultado: **PASA**.

La cuenta API local, única y activa, se amplió desde los `7` permisos de la
línea base hasta los `25` mínimos definidos por la batería. Se añadieron `18`
filas de forma idempotente en `prestashop_factuzam_lab`; no se cambió la clave,
la cuenta ni ninguna otra configuración.

| Recurso | Métodos efectivos |
|---|---|
| `addresses` | `GET` |
| `carriers` | `GET` |
| `categories` | `GET`, `POST` |
| `combinations` | `GET`, `POST`, `PATCH` |
| `customer_messages` | `GET` |
| `customer_threads` | `GET` |
| `customers` | `GET` |
| `images` | `GET`, `POST` |
| `order_states` | `GET` |
| `orders` | `GET` |
| `product_option_values` | `GET`, `POST` |
| `product_options` | `GET`, `POST` |
| `products` | `GET`, `POST`, `PATCH` |
| `shops` | `GET` |
| `states` | `GET` |
| `stock_availables` | `GET`, `PATCH` |

- La propia raíz autenticada de la API publica esta misma matriz.
- Los `GET` reales sobre los `16` recursos devolvieron HTTP `200`.
- Se probaron todos los `POST` y `PATCH` mediante XML deliberadamente
  malformado e identificadores inexistentes. Ninguno recibió `401`, `403` ni
  `405`: la petición superó autenticación y autorización y fue rechazada antes
  de persistir. La imagen inválida devolvió `400`; los XML inválidos devolvieron
  `500`.
- Permisos `DELETE`: `0`.

Después de estas pruebas se conservaron los recuentos originales: `19`
productos, `39` combinaciones, `23` imágenes, `2` clientes, `5` carros y `5`
pedidos. El árbol de imágenes conserva exactamente la misma cantidad, tamaño y
SHA-256 de manifiesto anotados en la línea base.

La matriz ampliada se conserva para las puertas posteriores. Al finalizar la
ejecución funcional completa debe ejecutarse
`PUERTA_A_PRESTASHOP_PERMISOS_RESTAURAR.sql` contra el MariaDB local y volver a
auditar `/api`. El resultado correcto de la restauración es `7` permisos y
ningún `DELETE`.
