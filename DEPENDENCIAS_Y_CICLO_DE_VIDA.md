# Dependencias y ciclo de vida

Este documento fija la propiedad de las dependencias compartidas y de los
recursos con estado. Su objetivo es evitar conexiones globales, objetos con
propietario ambiguo y trabajos en segundo plano que sobrevivan a sus datos.

## Composición

`TComposicionAplicacion` es la raíz de composición de la aplicación. Crea los
servicios de infraestructura y entrega contratos a `TfrmMtoPrincipal`. Los
formularios hijos heredan esos contratos de su propietario VCL, pero no toman
la propiedad de ellos.

La factoría `IFabricaContextosRepositoriosPantalla` se inyecta en `TfrmBase`.
Cada formulario crea perezosamente un `IContextoRepositoriosPantalla` nuevo y
lo conserva hasta que cambie alguna dependencia o se destruya la pantalla. La
factoría y el contexto son los únicos puntos que conocen los adaptadores
UniDAC; `TfrmBase` no crea repositorios concretos.

Los formularios funcionales agrupan sus casos de uso en contextos propios:

- `TContextoDependenciasFacturas`;
- `TContextoDependenciasOperacionCaja`;
- `TContextoDependenciasComprasSesiones`;
- `TContextoDependenciasInventario`;
- `TContextoDependenciasArticulos`;
- `TContextoDependenciasStockConsulta`.

Un contexto de pantalla contiene contratos o recursos que esa pantalla usa.
No recibe el formulario completo. Los adaptadores VCL reciben únicamente los
callbacks visuales necesarios y las aplicaciones reciben puertos de dominio.

## Reglas de propiedad

| Recurso | Propietario | Inicio | Fin | Regla para consumidores |
| --- | --- | --- | --- | --- |
| Conexión principal UniDAC | `TdmConn`, dentro de `TComposicionAplicacion` | Inicio de infraestructura | Después de detener workers y liberar servicios | Prestada; nunca liberarla ni desconectarla desde una pantalla o repositorio |
| Conexión secundaria | Servicio que la crea | Antes de su operación o worker | Al terminar la operación o detener el worker | No conservarla fuera del servicio creador |
| Contexto de repositorios | Formulario que retiene la interfaz | Primer uso de persistencia | Cambio de dependencias o destrucción del formulario | Posee interfaces; toma prestada la conexión principal |
| Repositorio UniDAC | Interfaz, servicio o contexto que lo retiene | Composición del caso de uso | Al liberar la última interfaz | Toma prestada la conexión; no conoce ni libera formularios |
| Data module VCL | Su `Owner` VCL o la composición | Construcción de pantalla o servicio | Destrucción del `Owner` | No liberarlo también de forma manual |
| Dataset colocado en DFM | Componente propietario | Construcción del formulario o data module | Destrucción del propietario | Los servicios pueden usarlo, pero no liberarlo |
| Dataset creado por un repositorio | Repositorio o resultado de consulta documentado | Ejecución de la consulta | Liberación del resultado o repositorio | La vista solo lo enlaza y deshace el enlace antes de liberar el resultado |
| Worker o tarea | Coordinador que lo inicia | Inicio explícito del proceso | `Terminate`/espera antes de liberar sus dependencias | No capturar formularios; usar contratos estables y log inyectado |
| Buffer, stream o lista temporal | Método u objeto que lo crea | Entrada en la operación | Bloque `try/finally` de la misma operación | Una devolución que transfiere propiedad debe indicarlo en el contrato |
| Callback VCL | Pantalla | Composición del adaptador | Destrucción de la pantalla | Referencia prestada; no debe generar ciclos de interfaces |

## Orden de cierre

El cierre de la aplicación respeta este orden:

1. impedir el inicio de nuevas operaciones;
2. solicitar la parada de workers y esperar su finalización;
3. liberar resultados, datasets temporales y contextos de pantalla;
4. liberar repositorios y servicios de aplicación;
5. invalidar los servicios de conexión y monitorización;
6. destruir el data module que posee la conexión;
7. liberar el registro de log y el contexto de sesión.

Una pantalla se cierra en sentido inverso a su composición: primero desliga
los `TDataSource`, después libera resultados y objetos propios, y finalmente
vacía sus interfaces. La destrucción de un contexto UniDAC pone a `nil` sus
interfaces y su referencia prestada a la conexión; nunca libera la conexión.

## Límites obligatorios

- El código de aplicación depende de `IRegistroLog`; solamente el adaptador
  `inLibLog` conoce la implementación concreta del log.
- La configuración de campos se obtiene mediante `IConfiguracionCampos`; no
  existe una instancia global `oConfigCampos`.
- `TfrmBase` distribuye contratos y solicita un contexto a una factoría
  inyectada. No contiene métodos `CrearRepositorio*` ni usa unidades UniDAC.
- Un evento VCL recoge datos, ejecuta un caso de uso y presenta el resultado.
- Ningún repositorio, aplicación o presentador recibe un formulario completo.
- Una referencia VCL capturada por callbacks es débil: el contexto se libera
  antes de destruir la pantalla para evitar llamadas tardías.

## Incorporación de una pantalla

Para una pantalla nueva se define primero un contexto pequeño con sus casos de
uso. La raíz de composición construye los adaptadores UniDAC y VCL, los inyecta
en los casos de uso y asigna estos al contexto. Si aparece una dependencia que
no pertenece a la capacidad de la pantalla, se crea un puerto nuevo en vez de
añadir acceso global o pasar el formulario completo.
