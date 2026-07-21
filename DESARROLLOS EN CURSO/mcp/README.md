# MCP de Factuzam

Servidor MCP sencillo (transporte stdio) que expone herramientas de
consulta sobre la BBDD de Factuzam en MariaDB. Pensado para conectarlo
a Claude Code / Claude Desktop y poder preguntar por datos de la
aplicacion en lenguaje natural.

Primera herramienta implementada:

| Herramienta       | Descripcion                                        |
|-------------------|----------------------------------------------------|
| `buscar_clientes` | Busqueda de clientes por texto libre en `fza_clientes` |

La busqueda compara el texto contra codigo, razon social, NIF, email,
telefono, movil, poblacion y referencia. Parametros:

- `texto` — texto a buscar (vacio = listar los primeros).
- `solo_activos` — por defecto `True`; con `False` incluye bajas.
- `limite` — maximo de filas, entre 1 y 100 (defecto 20).

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
