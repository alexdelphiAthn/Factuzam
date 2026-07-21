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

## Proximos pasos

- `ficha_cliente(codigo)` — ficha completa de un cliente.
- Busqueda de articulos y consulta de stock.
- Consulta de facturas / deuda por cliente.
