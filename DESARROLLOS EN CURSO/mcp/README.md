# MCP de Factuzam

Servidor MCP sencillo (transporte stdio) que expone herramientas de
consulta sobre la BBDD de Factuzam en MariaDB. Pensado para conectarlo
a Claude Code / Claude Desktop y poder preguntar por datos de la
aplicacion en lenguaje natural.

Herramientas implementadas:

| Herramienta       | Descripcion                                        |
|-------------------|----------------------------------------------------|
| `buscar_clientes` | Busqueda de clientes por texto libre en `fza_clientes` |
| `buscar_facturas` | Busqueda de facturas por cliente y fechas, mas recientes primero |
| `ventas_por_fecha`| Resumen de ventas de un periodo: articulos vendidos y totales |
| `ventas_agrupadas`| Ventas de un periodo agrupadas por familia o temporada |
| `comparar_ventas` | Comparativa de ventas entre dos periodos (con % de variacion) |
| `stock_articulos` | Stock actual por SKU o por articulo, con totales de valoracion |
| `deuda_clientes`  | Deuda actual por cliente y depositos pendientes de abonar |
| `factura_pdf`     | Extrae a fichero el PDF archivado de una factura (`fza_facturas.PDF_FAC`) |

`buscar_clientes` compara el texto contra codigo, razon social, NIF,
email, telefono, movil, poblacion y referencia. Parametros:

- `texto` — texto a buscar (vacio = listar los primeros).
- `solo_activos` — por defecto `True`; con `False` incluye bajas.
- `limite` — maximo de filas, entre 1 y 100 (defecto 20).

`buscar_facturas(cliente, desde, hasta, solo_consolidadas, limite)`
compara `cliente` contra codigo (exacto), razon social y NIF
(contiene); `desde`/`hasta` acotan la fecha (AAAA-MM-DD). Por defecto
solo facturas emitidas. Cada fila indica si tiene PDF archivado.

`ventas_por_fecha(desde, hasta, cliente, solo_consolidadas,
incluir_canceladas, limite_articulos)` responde a preguntas tipo "las
ventas de hoy": `desde`/`hasta` en formato AAAA-MM-DD (vacios = hoy;
`hasta` vacio = mismo dia que `desde`); `cliente` filtra opcionalmente
igual que en `buscar_facturas`. Devuelve:

- `resumen` — numero de facturas, unidades vendidas, bases, impuestos,
  retenciones y total liquido del periodo (de `fza_facturas`).
- `articulos` — lineas de `fza_facturas_lineas` agregadas por articulo
  (codigo, descripcion, cantidad, total sin IVA y total con IVA),
  ordenadas de mayor a menor venta (hasta `limite_articulos`, defecto
  100, maximo 500).
- `facturas` — lista breve de las facturas del periodo.

Por defecto solo cuenta facturas consolidadas y excluye las de fase
CANCELADA. Las rectificativas/abonos entran con su signo, asi que el
total es la venta neta del periodo.

Con `con_fotos` (defecto `True`) el resultado acompana la foto 300 px
de cada articulo del listado (hasta `limite_fotos`, defecto 12, maximo
50) como imagenes MCP, en el mismo orden del listado y cada una
precedida de su codigo y descripcion. Usa las fotos de
`<appDirFotos>/300/<nombre>.png` (ver `../fotos_articulos.md`) con la
misma regla de resolucion que la aplicacion: foto a nivel articulo y,
en su defecto, la unica foto del articulo si solo tiene una. La
carpeta se toma de `FACTUZAM_DIR_FOTOS` o, si no esta definida, del
parametro `appDirFotos` guardado en la BBDD (expandiendo `$(PUBLICO)`);
si el servidor MCP corre en otra maquina y no ve esa carpeta, el
listado sale igualmente, solo que sin imagenes
(`foto_disponible: false` en cada articulo).

`ventas_agrupadas(desde, hasta, agrupar, cliente, ...)` agrupa las
ventas del periodo por `familia` (columnas de familia de la linea de
factura) o por `temporada` (propiedad TEMPORADA del articulo/color
vendido, con herencia articulo → color como en la aplicacion). Cada
grupo lleva cantidad, total sin/con IVA y porcentaje sobre la venta.

`comparar_ventas(desde1, hasta1, desde2, hasta2, agrupar, cliente,
...)` compara dos periodos: resumen de cada uno y `diferencias`
(variacion absoluta y porcentual). Si `desde2`/`hasta2` van vacios se
compara con el periodo inmediatamente anterior de la misma duracion.
Con `agrupar` ('familia' o 'temporada') añade la comparativa por
grupos.

`stock_articulos(texto, almacen, solo_con_stock, por_articulo,
limite)` consulta `fza_articulos_stockactual`: filtra por codigo,
descripcion o SKU (contiene) y opcionalmente por almacen; con
`por_articulo` agrega el desglose de tallas/colores. Devuelve cantidad,
pendientes de recibir/servir, precio medio y valor, mas los totales de
todo lo filtrado.

`deuda_clientes(cliente, solo_con_deuda, con_depositos, limite)`
calcula la deuda en vivo con la formula de la aplicacion (ver
`../clientes_deuda_actual.sql`): depositos/prestamos PENDIENTE con
cantidad positiva, sumando precio x cantidad pendiente menos
anticipos. Cada cliente sale con su deuda, anticipos entregados,
`deuda_ficha` (el TOTAL_DEUDA_CLI guardado, por si estuviera
desactualizado) y el detalle de depositos pendientes de abonar.

`factura_pdf(serie, numero)` vuelca el PDF que Factuzam archiva al
consolidar la factura (ver `../facturas_pdf_blob.md`) a la carpeta
`FACTUZAM_DIR_PDF` (o la temporal del sistema) y devuelve ruta, nombre,
tamano, huella SHA-256, formato e instante de archivado.

Flujo tipico — "dame la ultima factura de Agustin":
1. `buscar_clientes('Agustin')` → codigo de cliente.
2. `buscar_facturas(cliente='294', limite=1)` → serie y numero.
3. `factura_pdf('2026.A1', '000123')` → ruta del PDF extraido.

Solo lanza SELECT: el servidor no modifica datos.

## Requisitos

- Python 3.10 o superior.
- Acceso de red a la MariaDB de Factuzam.

Instalacion de dependencias:

```bash
pip install -r requirements.txt
```

## Configuracion

La conexion se configura por variables de entorno:

| Variable                | Defecto     | Descripcion          |
|-------------------------|-------------|----------------------|
| `FACTUZAM_BBDD_HOST`    | `127.0.0.1` | Host de MariaDB      |
| `FACTUZAM_BBDD_PUERTO`  | `3306`      | Puerto               |
| `FACTUZAM_BBDD_USUARIO` | `root`      | Usuario              |
| `FACTUZAM_BBDD_CLAVE`   | *(vacia)*   | Contrasena           |
| `FACTUZAM_BBDD_NOMBRE`  | `factuzam`  | Nombre de la BBDD    |
| `FACTUZAM_DIR_PDF`      | *(temporal)*| Carpeta donde extraer los PDF |
| `FACTUZAM_DIR_FOTOS`    | *(appDirFotos de la BBDD)* | Carpeta de fotos de articulos |
| `FACTUZAM_MCP_TRANSPORTE`| `stdio`    | `stdio` (local) o `http` (remoto) |
| `FACTUZAM_MCP_HOST`     | `127.0.0.1` | Escucha del modo http |
| `FACTUZAM_MCP_PUERTO`   | `8974`      | Puerto del modo http  |
| `FACTUZAM_MCP_TOKEN`    | *(vacio)*   | Si se define, exige `Authorization: Bearer <token>` |

Recomendable usar un usuario MariaDB de solo lectura para el MCP.

## Alta en Claude Code

Desde el directorio del repo:

```bash
claude mcp add factuzam \
  --env FACTUZAM_BBDD_HOST=127.0.0.1 \
  --env FACTUZAM_BBDD_USUARIO=factuzam_ro \
  --env FACTUZAM_BBDD_CLAVE=xxxx \
  --env FACTUZAM_BBDD_NOMBRE=factuzam \
  -- python "DESARROLLOS EN CURSO/mcp/servidor_mcp.py"
```

## Alta en Claude Desktop

Anadir al `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "factuzam": {
      "command": "python",
      "args": ["C:/ruta/al/repo/DESARROLLOS EN CURSO/mcp/servidor_mcp.py"],
      "env": {
        "FACTUZAM_BBDD_HOST": "127.0.0.1",
        "FACTUZAM_BBDD_USUARIO": "factuzam_ro",
        "FACTUZAM_BBDD_CLAVE": "xxxx",
        "FACTUZAM_BBDD_NOMBRE": "factuzam"
      }
    }
  }
}
```

## Modo HTTP (acceso remoto: claude.ai, ChatGPT, moviles)

El mismo servidor puede exponerse por HTTP (endpoint `/mcp`, protocolo
MCP "streamable http") para clientes que no lanzan procesos locales:

```bash
set FACTUZAM_MCP_TRANSPORTE=http
set FACTUZAM_MCP_TOKEN=un-token-largo-y-aleatorio
python servidor_mcp.py
```

Escucha en `http://127.0.0.1:8974/mcp`. Con `FACTUZAM_MCP_TOKEN`
definido, toda peticion sin `Authorization: Bearer <token>` recibe 401.

### Despliegue recomendado en la oficina

1. **Servicio**: arrancar `servidor_mcp.py` como servicio junto a
   MariaDB (Windows: Programador de tareas "al iniciar el equipo" o
   NSSM; Linux: unidad systemd). Siempre con usuario BBDD de solo
   lectura (`factuzam_ro`) y escucha en `127.0.0.1`.
2. **HTTPS hacia internet**: NO abrir el puerto 8974 directamente.
   Opciones, de mas a menos recomendada:
   - **Cloudflare Tunnel** (`cloudflared tunnel --url
     http://127.0.0.1:8974`): sin abrir puertos en el router, da una
     URL HTTPS publica; con Cloudflare Access se puede exigir ademas
     login por email.
   - **Reverse proxy en el servidor web existente** (Apache/nginx/IIS):
     `ProxyPass /mcp http://127.0.0.1:8974/mcp` con certificado TLS
     (Let's Encrypt) y el dominio de la empresa.
   - VPN (Tailscale/WireGuard) si solo van a consultar empleados.
3. **MariaDB nunca se expone**: solo el MCP sale a internet, y es de
   solo lectura + token.

### Alta en los clientes

- **Claude Code**: `claude mcp add factuzam --transport http
  https://tu-dominio/mcp --header "Authorization: Bearer <token>"`.
- **claude.ai / app movil de Claude**: Configuracion → Conectores →
  "Añadir conector personalizado" con la URL `https://tu-dominio/mcp`
  (planes de pago; si la UI no permite cabeceras, proteger con
  Cloudflare Access en lugar de token).
- **ChatGPT**: Configuracion → Conectores → conector personalizado MCP
  con la misma URL (planes de pago; requiere URL publica HTTPS).

La disponibilidad exacta de conectores MCP por plan/plataforma cambia
con frecuencia: verificar con el plan del cliente al desplegar.

## Proximos pasos

- `ficha_cliente(codigo)` — ficha completa de un cliente.
