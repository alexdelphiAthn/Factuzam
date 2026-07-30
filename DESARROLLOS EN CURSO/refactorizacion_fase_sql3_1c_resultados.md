# Resultado de la fase SQL-3.1c

Fecha de cierre: 30/07/2026.

## Alcance

Se han extraído las lecturas internas de la materialización y reversión de
sesiones de compra sin mover las escrituras ni alterar el límite de la
unidad de trabajo.

La auditoría encontró diecisiete construcciones de lectura:

- doce en artículos;
- una en documentos comunes;
- una en estado;
- una en pedidos;
- dos en reversión.

Se catalogan como dieciséis operaciones porque `BuscarValorColor` sirve
tanto para localizar un valor existente como para recuperar el valor
recién insertado.

## Diseño resultante

`ILecturasMaterializacionComprasSesiones` es un contrato sin UniDAC. Sus
resultados son registros y arrays definidos en
`inLibComprasSesionesMaterializacionIntf`.

`TRepositorioLecturasMaterializacionComprasSesiones`:

- contiene el SQL base de las dieciséis lecturas;
- resuelve cada operación desde `SQL_REPOSITORIOS`;
- valida parámetros y campos obligatorios;
- registra la causa de descarte o fallo;
- reintenta la lectura una vez con el SQL base.

La composición crea una sola instancia del repositorio técnico y la
inyecta en artículos, pedidos, albaranes, estado y reversión. Las fachadas
originales conservan las escrituras, pero ya no construyen SQL de lectura.

## Catálogo

Repositorio: `RepositorioMaterializacionComprasSesiones`.

Todas las operaciones tienen política
`pesPerfilLecturaConFallback`. El registro de aplicación pasa de 104 a
120 definiciones:

- 116 lecturas sustituibles;
- dos comprobaciones técnicas `pesSoloBase`;
- dos escrituras de Facturas `pesSoloBase`.

El interruptor continúa siendo el de la pantalla:

```text
KEY_USUPER = frmMtoComprasSesiones
SUBKEY_USUPER = oGetSQLFromDB
```

Las consultas se administran bajo:

```text
KEY_USUPER = SQL_REPOSITORIOS
SUBKEY_USUPER =
  SQL__RepositorioMaterializacionComprasSesiones__Operacion
```

## Verificación

- Compilación DUnitX Win64 correcta, incluida la guarda de integración de
  los adaptadores modificados.
- 386 pruebas encontradas y 386 superadas, sin ignoradas, fugas, fallos ni
  errores.
- La guarda de compilación `CompilarIntegracionSql31c` generó los DCU de
  todos los adaptadores modificados.
- `comprobar_sql_en_dominio.ps1`: correcto, 286 sentencias en 63 unidades.
- `comprobar_sql_transacciones.ps1`: correcto.
- La compilación principal Win64 sigue detenida por la dependencia externa
  ya conocida `frxClass`, antes de enlazar el ejecutable.
