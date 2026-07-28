# Plan de extracción de literales y futura traducción

Fecha de inicio: 27/07/2026.

Objetivo: centralizar los textos visibles escritos en código, empezando por
`inLibMsg`, y preparar después la traducción de formularios y proyectos
auxiliares sin cambiar el comportamiento de la aplicación.

## Estado e inventario inicial

El inventario se ha calculado sobre las 355 unidades Pascal incluidas en
`fzam.dproj`. Son cifras orientativas obtenidas por búsqueda estática y deben
recalcularse al comenzar cada tanda.

| Tipo de literal | Candidatos pendientes |
|---|---:|
| Diálogos con literal directo | 708 |
| Excepciones creadas con literal | 361 |
| `Caption`, `Hint`, `Title` o `DisplayName` asignados en código | 468 |
| Propiedades visibles aproximadas en los DFM | 3.907 |

El piloto de `inMtoLogon` está terminado: no quedan literales directos en sus
llamadas a `ShowMessage`, `MessageDlg`, `InputBox` o `MessageBox`. El proyecto
compila en Win32 Debug.

Los recuentos no incluyen componentes de terceros de `src/3rdpartyComp/`.
Tampoco implican que todo texto encontrado sea traducible: cada candidato se
revisa antes de moverlo.

## Qué se mueve y qué no

Se mueve a `inLibMsg`:

- Texto presentado mediante `ShowMessage`, `ShowMessageFmt`, `MessageDlg`,
  `MessageBox`, `InputBox`, `InputQuery` o diálogos equivalentes.
- Mensajes de excepciones que puedan alcanzar el manejador global y mostrarse
  al usuario.
- Plantillas completas de mensajes dinámicos, usando `Format`.
- En una segunda fase, textos visibles asignados en ejecución a `Caption`,
  `Hint`, `Title` y propiedades semejantes.

No se mueve:

- SQL, nombres de tablas, columnas, parámetros o procedimientos almacenados.
- Claves de INI, registro, JSON, XML o configuración.
- Nombres de componentes, clases, unidades, eventos o identificadores.
- Rutas, extensiones y filtros técnicos que no se muestran al usuario.
- Mensajes usados exclusivamente en el log, salvo que también lleguen a UI.
- Textos de código de terceros.

Los DFM se tratan en una fase propia. No se convertirán sus miles de
`Caption` en asignaciones dentro de `FormCreate`: antes hay que definir un
mecanismo de localización de formularios.

## Convenciones de extracción

1. Mantener el texto completo en una sola entrada. No concatenar fragmentos
   traducibles desde el formulario.
2. Usar marcadores `%s`, `%d`, etc. y `Format` cuando haya valores dinámicos.
3. Conservar saltos de línea, icono, botones, botón predeterminado y resultado
   del diálogo.
4. Añadir `inLibMsg` al `uses` de `implementation` siempre que sea posible.
5. No reutilizar una entrada solo porque hoy tenga el mismo texto si los
   contextos funcionales son distintos.
6. Mantener durante la extracción el mecanismo actual de variables de
   `inLibMsg`. La posible migración a `resourcestring` o a catálogos cargados
   por idioma será una tarea independiente.
7. Agrupar las entradas de `inLibMsg` por dominio con comentarios breves.
8. Mantener UTF-8 con BOM, CRLF y líneas de un máximo de 80 columnas.

Prefijos recomendados:

| Prefijo | Uso |
|---|---|
| `SInfo` | Resultado informativo |
| `SAviso` | Advertencia sin pregunta |
| `SError` | Error mostrado al usuario |
| `SPregunta` | Confirmación o elección |
| `SSolicitud` | Texto de entrada de datos |
| `STitulo` | Título de diálogo o ventana |

El dominio se añade al final cuando evite ambigüedad:
`SErrorGuardarFactura`, `SPreguntaBorrarCliente`,
`SSolicitudPassBBDD`.

## Fase M — diálogos y excepciones visibles

Cada tanda incluye los diálogos directos y la revisión de las excepciones del
mismo alcance. La columna «candidatos» suma ambos tipos; no es un compromiso de
moverlos todos.

Estados permitidos: `PENDIENTE`, `EN CURSO`, `COMPILADO`, `PROBADO` y
`BLOQUEADO`.

| Tanda | Alcance | Candidatos | Estado |
|---|---|---:|---|
| M00 | `src/Core/inMtoLogon.pas` | Piloto | COMPILADO |
| M01 | Core, excepto Logon | 42 | COMPILADO |
| M02 | DataModules `UniDataA*` a `UniDataC*` | 36 | COMPILADO |
| M03 | DataModules `UniDataD*` a `UniDataF*` | 81 | COMPILADO |
| M04 | DataModules `UniDataG*` a `UniDataM*` | 38 | COMPILADO |
| M05 | Resto de DataModules | 35 | COMPILADO |
| M06 | Lib `inLibA*` a `inLibD*` | 94 | COMPILADO |
| M07 | Lib `inLibE*` a `inLibH*` | 94 | COMPILADO |
| M08 | Lib `inLibI*` a `inLibP*` y resto intermedio | 51 | COMPILADO |
| M09 | Lib `inLibQ*` a `inLibZ*` | 157 | COMPILADO |
| M10 | `Lib3par` propia y `verifactu` | 53 | COMPILADO |
| M11 | Forms `inMtoA*` a `inMtoB*` | 69 | COMPILADO |
| M12 | Forms `inMtoC*` | 57 | COMPILADO |
| M13 | Forms `inMtoD*` a `inMtoE*` | 66 | COMPILADO |
| M14 | Forms `inMtoF*` | 83 | COMPILADO |
| M15 | Forms `inMtoG*` a `inMtoI*` | 103 | COMPILADO |
| M16 | Forms `inMtoJ*` a `inMtoP*` | 48 | COMPILADO |
| M17 | Forms `inMtoQ*` a `inMtoZ*` | 113 | COMPILADO |
| M18 | Modals `inMtoModalA*` a `inMtoModalF*` | 70 | COMPILADO |
| M19 | Modals `inMtoModalG*` a `inMtoModalM*` | 52 | COMPILADO |
| M20 | Modals `inMtoModalN*` a `inMtoModalZ*` | 34 | COMPILADO |
| M21 | Caja: DataModules y Lib | 32 | COMPILADO |
| M22 | Caja: Forms `inMtoA*` a `inMtoM*` | 67 | COMPILADO |
| M23 | Caja: Forms `inMtoN*` a `inMtoZ*` | 22 | COMPILADO |
| M24 | Caja: Modals | 19 | COMPILADO |

Orden recomendado: M01, M11-M20, M02-M10 y M21-M24. Así se limpian primero
los textos de UI directa y después las capas de negocio, donde hay que decidir
qué excepciones son visibles y cuáles son exclusivamente técnicas.

## Fase R — textos visibles asignados en ejecución

Esta fase empieza cuando M01-M24 estén compiladas. Se revisan únicamente
asignaciones que llegan a controles o diálogos; no se extraen valores de
estado internos.

| Tanda | Alcance | Candidatos | Estado |
|---|---|---:|---|
| R01 | Core | 28 | PENDIENTE |
| R02 | Forms A-B | 33 | PENDIENTE |
| R03 | Forms C | 8 | PENDIENTE |
| R04 | Forms D-E | 18 | PENDIENTE |
| R05 | Forms F | 60 | PENDIENTE |
| R06 | Forms G-I | 34 | PENDIENTE |
| R07 | Forms J-P | 26 | PENDIENTE |
| R08 | Forms Q-Z | 29 | PENDIENTE |
| R09 | Modals A-F | 31 | PENDIENTE |
| R10 | Modals G-M | 57 | PENDIENTE |
| R11 | Modals N-Z | 27 | PENDIENTE |
| R12 | Caja Forms A-M | 29 | PENDIENTE |
| R13 | Caja Forms N-Z | 31 | PENDIENTE |
| R14 | Caja Modals | 5 | PENDIENTE |
| R15 | Lib | 50 | PENDIENTE |
| R16 | Verifactu | 2 | PENDIENTE |

## Fase D — formularios DFM y selector de idioma

El `TcxLocalizer` de `TfrmBase` está fijado actualmente al locale español
1034 y localiza cadenas de Developer Express. No existe todavía un mecanismo
general para traducir los textos propios guardados en los DFM.

Antes de tocar los DFM:

- [ ] Elegir el origen de traducciones: recursos, fichero por idioma o BBDD.
- [ ] Definir una clave estable que no dependa del texto español.
- [ ] Implementar la aplicación de idioma desde `TfrmBase`.
- [ ] Añadir idioma configurado y fallback a español.
- [ ] Preparar un pseudoidioma que alargue textos para detectar recortes.
- [ ] Verificar formularios heredados y controles DevExpress.

Inventario para seguimiento:

| Tanda | Alcance | Propiedades aproximadas | Estado |
|---|---|---:|---|
| D01 | Infraestructura y selector de idioma | No aplica | PENDIENTE |
| D02 | Core | 126 | PENDIENTE |
| D03 | Forms A-B | 512 | PENDIENTE |
| D04 | Forms C | 540 | PENDIENTE |
| D05 | Forms D-E | 346 | PENDIENTE |
| D06 | Forms F | 540 | PENDIENTE |
| D07 | Forms G-I | 196 | PENDIENTE |
| D08 | Forms J-P | 408 | PENDIENTE |
| D09 | Forms Q-Z | 212 | PENDIENTE |
| D10 | Modals A-F | 265 | PENDIENTE |
| D11 | Modals G-M | 143 | PENDIENTE |
| D12 | Modals N-Z | 131 | PENDIENTE |
| D13 | Caja Forms A-M | 279 | PENDIENTE |
| D14 | Caja Forms N-Z | 10 | PENDIENTE |
| D15 | Caja Modals | 168 | PENDIENTE |
| D16 | Verifactu | 31 | PENDIENTE |

## Fase A — aplicaciones auxiliares

Los proyectos independientes no deben depender automáticamente del
`inLibMsg` del ejecutable principal. En cada uno se decidirá si comparte un
catálogo común o si necesita su propia unidad de mensajes.

| Tanda | Alcance | Estado |
|---|---|---|
| A01 | `utilnormbbdd` | PENDIENTE |
| A02 | `utilmigsqlsrv` | PENDIENTE |
| A03 | Aplicaciones FMX de recuento y ventas | PENDIENTE |
| A04 | `certapiweb` y herramientas de fotos | PENDIENTE |
| A05 | Utilidades y pruebas con uso real confirmado | PENDIENTE |

Quedan fuera de alcance las copias de terceros, demos de proveedores y pruebas
abandonadas. Antes de incluir una prueba o utilidad se confirma que sigue
siendo un producto mantenido.

## Pruebas obligatorias por tanda

### Comprobación estática

- [ ] No quedan diálogos con literal directo dentro del alcance.
- [ ] No quedan excepciones visibles con literal directo dentro del alcance.
- [ ] Cada identificador nuevo está declarado una sola vez.
- [ ] Los marcadores de `Format` coinciden en número y tipo con sus argumentos.
- [ ] No se han movido SQL, claves técnicas ni nombres de campos.
- [ ] No hay líneas nuevas de más de 80 columnas.
- [ ] Los `.pas` modificados conservan UTF-8 con BOM y CRLF.
- [ ] `git diff --check` no informa de errores.

### Compilación

- [ ] Compilar `fzam.dproj`, Win32 Debug, después de cada tanda.
- [ ] Compilar Win32 Release y Win64 Release al cerrar cada fase.
- [ ] Comparar warnings y hints con la referencia anterior.

### Prueba funcional

Para cada mensaje tocado se intenta ejecutar, cuando sea seguro:

1. Camino correcto.
2. Error o validación.
3. Cancelación.
4. Confirmación afirmativa y negativa.
5. Mensaje con datos dinámicos.

Se comprueba que el texto, los saltos de línea, el icono, los botones y el
resultado del diálogo no han cambiado. Si un camino destructivo no puede
probarse, se deja anotado como no ejecutado y no se simula en producción.

Pruebas mínimas por familia:

| Familia | Smoke test |
|---|---|
| Core | Arranque, logon, configuración, menú y preview |
| Maestros | Abrir, validar, grabar y cancelar una ficha |
| Ventas | Factura, albarán, pedido, efecto y remesa |
| Compras | Sesión, pedido, albarán, factura y devolución |
| Inventario | Crear, recalcular, grabar y cancelar |
| Modales | Abrir, validar, aceptar y cancelar |
| Caja | Venta, cobro, pago, traspaso y arqueo |
| Verifactu | Validación, cola, declaración y log |

## Registro de resultados

Se añade una fila al terminar cada tanda. `PROBADO` exige compilación y smoke
test; si solo compila, el estado permanece en `COMPILADO`.

| Fecha | Tanda | Build | Auditoría estática | Smoke test | Incidencias |
|---|---|---|---|---|---|
| 27/07/2026 | M00 | Win32 Debug OK | Sin literales en diálogos | No ejecutado | Ninguna |
| 27/07/2026 | M01 | Win32 Debug OK | 42 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M02 | Win32 Debug OK | 36 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M03 | Win32 Debug OK | 81 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M04 | Win32 Debug OK | 38 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M05 | Win32 Debug OK | 35 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M06 | Win32 Debug OK | 94 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M07 | Win32 Debug OK | 94 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M08 | Win32 Debug OK | 51 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M09 | Win32 Debug OK | 157 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M10 | Win32 Debug OK | 53 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M11 | Win32 Debug OK | 69 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M12 | Win32 Debug OK | 57 revisados; 0 directos | No ejecutado | Un hint previo |
| 27/07/2026 | M13 | Win32 Debug OK | 66 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M14 | Win32 Debug OK | 83 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M15 | Win32 Debug OK | 103 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M16 | Win32 Debug OK | 48 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M17 | Win32 Debug OK | 113 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M18 | Win32 Debug OK | 70 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M19 | Win32 Debug OK | 52 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M20 | Win32 Debug OK | 34 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M21 | Win32 Debug OK | 32 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M22 | Win32 Debug OK | 67 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M23 | Win32 Debug OK | 22 revisados; 0 directos | No ejecutado | Un hint previo |
| 28/07/2026 | M24 | Win32 Debug OK | 19 revisados; 0 directos | No ejecutado | Un hint previo |

## Criterio de finalización

El proyecto se considerará preparado para incorporar un segundo idioma cuando:

- Todas las tandas M y R estén en estado `PROBADO`.
- D01 esté implementada y las tandas D estén probadas con pseudoidioma.
- No haya literales visibles directos en código propio del ejecutable.
- El idioma español reproduzca los textos y flujos actuales.
- Un segundo catálogo pueda cargarse sin recompilar formularios.
- Win32 y Win64 compilen sin nuevos warnings.

