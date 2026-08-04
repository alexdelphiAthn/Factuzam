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
| `SCaption` | Texto de control asignado en ejecución |
| `SHint` | Texto de ayuda emergente |

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
| R01 | Core | 28 | COMPILADO |
| R02 | Forms A-B | 33 | COMPILADO |
| R03 | Forms C | 8 | COMPILADO |
| R04 | Forms D-E | 18 | COMPILADO |
| R05 | Forms F | 60 | COMPILADO |
| R06 | Forms G-I | 34 | COMPILADO |
| R07 | Forms J-P | 26 | COMPILADO |
| R08 | Forms Q-Z | 29 | COMPILADO |
| R09 | Modals A-F | 31 | COMPILADO |
| R10 | Modals G-M | 57 | COMPILADO |
| R11 | Modals N-Z | 27 | COMPILADO |
| R12 | Caja Forms A-M | 29 | COMPILADO |
| R13 | Caja Forms N-Z | 31 | COMPILADO |
| R14 | Caja Modals | 5 | COMPILADO |
| R15 | Lib | 50 | COMPILADO |
| R16 | Verifactu | 2 | COMPILADO |

Las tandas R01-R16 quedaron extraídas y auditadas estáticamente el
30/07/2026 con los prefijos `SCaption`, `SHint` y `STitulo`. La
compilación Win32 Debug de cierre la ejecuta el usuario.

## Fase D — formularios DFM y selector de idioma

`TfrmBase` aplica el idioma de `fza_traducciones` a los textos de los DFM,
los `resourcestring` y las cadenas de Developer Express. El locale español
1034 se conserva únicamente para cargar el respaldo compilado.

Antes de tocar los DFM:

- [x] Elegir el origen de traducciones: BBDD (`fza_traducciones`).
- [x] Definir una clave estable que no dependa del texto español.
- [x] Implementar la aplicación de idioma desde `TfrmBase`.
- [x] Añadir idioma configurado y fallback a español.
- [x] Preparar un pseudoidioma que alargue textos para detectar recortes.
- [x] Verificar formularios heredados y controles DevExpress.

La clave de una propiedad sigue el formato:

`<unidad>.<clase raíz>[.<componente>].<propiedad>`

Ejemplo:

`inMtoLogon.TfrmLogon.lblUsuario.Caption`

Las propiedades iniciales son `Caption`, `Hint`, `Title` y `DisplayName`.
El servicio conserva el texto del DFM cuando no encuentra la clave. Las
unidades que no heredan de `TfrmBase` pueden recibir `IServicioTraducciones`
o llamar a `AplicarTraducciones` pasando el componente y su propietario.

El parámetro `appIdioma` selecciona el idioma. El valor predeterminado es
`es-ES` y `qps-ploc` activa el pseudoidioma.

Los catálogos de DFM se generan con
`generar_traducciones_dfm.ps1`. El generador omite textos vacíos y
separadores de menú, y produce un `INSERT ... ON DUPLICATE KEY UPDATE`
idempotente. Las propiedades publicadas dentro de colecciones se identifican
por su ruta e índice, por ejemplo
`control.Properties.ListColumns[0].Caption`.
En formularios heredados, el servicio busca primero la clave de la clase
concreta y después las de sus ancestros. Así se reutiliza el catálogo del
DFM base sin duplicarlo para cada descendiente.

D17 cierra la cobertura con `verificar_traducciones_dfm.ps1`. La prueba
reconstruye las claves de todos los DFM incluidos en `fzam.dproj` y las
compara con los catálogos D02-D16. No genera otro SQL porque duplicaría
entradas ya catalogadas.

D18 prueba el servicio con DUnitX: pseudoidioma, idempotencia, fallback,
normalización del idioma, claves de clases heredadas y colecciones
DevExpress.

Inventario para seguimiento:

| Tanda | Alcance | Propiedades aproximadas | Estado |
|---|---|---:|---|
| D01 | Infraestructura y selector de idioma | No aplica | COMPILADO |
| D02 | Core | 126 | COMPILADO |
| D03 | Forms A-B | 515 | COMPILADO |
| D04 | Forms C | 553 | COMPILADO |
| D05 | Forms D-E | 346 | COMPILADO |
| D06 | Forms F | 544 | COMPILADO |
| D07 | Forms G-I | 200 | COMPILADO |
| D08 | Forms J-P | 408 | COMPILADO |
| D09 | Forms Q-Z | 215 | COMPILADO |
| D10 | Modals A-F | 270 | COMPILADO |
| D11 | Modals G-M | 143 | COMPILADO |
| D12 | Modals N-Z | 143 | COMPILADO |
| D13 | Caja Forms A-M | 282 | COMPILADO |
| D14 | Caja Forms N-Z | 10 | COMPILADO |
| D15 | Caja Modals | 175 | COMPILADO |
| D16 | Verifactu | 31 | COMPILADO |
| D17 | Auditoría de cierre DFM | 3.961 | COMPILADO |
| D18 | Pruebas del servicio de traducciones | 6 | COMPILADO |
| D19 | `resourcestring` propios y VCL | 2.188 | COMPILADO |
| D20 | Developer Express centralizado en BBDD | 718 + ajustes | COMPILADO |
| D21 | Catálogo inglés completo | 6.863 | COMPILADO |
| D22 | Informes FastReport | 300 + BLOB | EN CURSO |
| D23 | Catálogo catalán e idioma ca-ES | 7.163 | EN CURSO |

D19 genera un registro estable `unidad.identificador` para los
`resourcestring` de las nueve unidades `inLibMsg*` y de la VCL local.
`utlTraduc` importa esos textos a la BBDD de forma idempotente. Factuzam
realiza el recorrido inverso en ejecución y sólo usa el texto compilado como
respaldo.

D20 importa `CXLOCALIZATION.res` y las personalizaciones españolas de la hoja
de cálculo con claves `DevExpress.<identificador>`. `TcxLocalizer.OnTranslate`
consulta la misma tabla, por lo que no queda otro catálogo activo en paralelo.
La sincronización del 30/07/2026 añadió 2.902 claves de código, VCL y
DevExpress. Con las 3.961 claves DFM ya cargadas, el catálogo español suma
6.863 textos activos.

D21 carga las 6.863 entradas `en-GB` mediante el script idempotente
`traducciones_en_gb_d21.sql`. La auditoría estructural conserva marcadores,
saltos de línea y aceleradores. La BBDD de desarrollo queda con 6.863 claves
españolas, 6.863 inglesas y cero pendientes.

D22-A extrae 300 textos visibles `Memo.UTF8W` de 23 plantillas FastReport
predeterminadas embebidas en los DFM. Las claves siguen el formato
`FastReport.<unidad>.Predeterminado.<objeto>.Memo`. El generador selecciona
entre `frxrprt1` y `frxReportOrigen` la copia que realmente contiene la
plantilla. D22-B traduce los formatos personalizados guardados como BLOB
en `fza_usuarios_perfiles` sin claves por formato: al cargar el `.frx`,
`inLibTraduccionesInforme` busca el texto español de cada memo en el
catálogo `FastReport.*` y lo sustituye por el del idioma activo. Así la
traducción no depende del nombre editable del formato ni exige catálogo
por instalación; los textos escritos a mano por el usuario permanecen
en español. La misma unidad aplica en ejecución las claves
`Predeterminado` de la plantilla base, con recorrido de clases
heredadas, y un pseudoidioma sin corchetes que no rompe las
expresiones del memo. La traducción se aplica solo en los flujos de
salida del modal de impresión (imprimir, vista preliminar, PDF y
Excel), nunca al editar, para no guardar textos traducidos en el BLOB.
`traducciones_en_gb_d22.sql` carga las 300 entradas `en-GB` del
catálogo FastReport con la misma auditoría estructural que D21.

D23 incorpora el catalán (`ca-ES`, LCID 1027) como tercer idioma. La
etiqueta sigue BCP 47 (`idioma-REGIÓN`), igual que `es-ES` y `en-GB`.
`NormalizarIdiomaAplicacion` acepta `ca-ES`, el selector de `appIdioma`
lo ofrece y la ayuda del parámetro lo documenta. El catálogo
`traducciones_ca_es_d23.sql` carga las 7.163 entradas `ca-ES`: 3.961
DFM, 300 FastReport y 1.761 resourcestrings propios traducidos desde
el español del repositorio; los 718 DevExpress y 423 VCL se traducen
desde el inglés de D21 porque su fuente española no está en el repo.
También actualiza la entrada `en-GB` de la ayuda de `appIdioma`. La
auditoría estructural conserva marcadores `%s`/`%d`, saltos de línea,
aceleradores `&` y expresiones de informe. DevExpress no necesita
cambios: mantiene el locale base 1034 y el catálogo `ca-ES` se aplica
por encima vía `OnTranslate`.

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
| 29/07/2026 | D01 | Win32 Debug OK | OK | No | Visual pendiente |
| 30/07/2026 | D02 | Win32 Debug OK | 126 claves | No | SQL no aplicado |
| 30/07/2026 | D03 | Win32/Win64 Debug OK | 515 claves | No | SQL no aplicado |
| 30/07/2026 | D04 | Win32/Win64 Debug OK | 553 claves | No | SQL no aplicado |
| 30/07/2026 | D05 | Win32/Win64 Debug OK | 346 claves | No | SQL no aplicado |
| 30/07/2026 | D06 | Win32/Win64 Debug OK | 544 claves | No | SQL no aplicado |
| 30/07/2026 | D07 | Win32 Debug OK | 200 claves | No | SQL no aplicado |
| 30/07/2026 | D08 | Win32 Debug OK | 408 claves | No | SQL no aplicado |
| 30/07/2026 | D09 | Win32 Debug OK | 215 claves | No | SQL no aplicado |
| 30/07/2026 | D10 | Win32 Debug OK | 270 claves | No | SQL no aplicado |
| 30/07/2026 | D11 | Win32 Debug OK | 143 claves | No | SQL no aplicado |
| 30/07/2026 | D12 | Win32 Debug OK | 143 claves | No | SQL no aplicado |
| 30/07/2026 | D13 | Win32 Debug OK | 282 claves | No | SQL no aplicado |
| 30/07/2026 | D14 | Win32 Debug OK | 10 claves | No | SQL no aplicado |
| 30/07/2026 | D15 | Win32 Debug OK | 175 claves | No | SQL no aplicado |
| 30/07/2026 | D16 | Win32 Debug OK | 31 claves | No | SQL no aplicado |
| 30/07/2026 | D17 | Win32 Debug OK | 3.961 claves | No | Auditoría DFM correcta |
| 30/07/2026 | D18 | Win32 Debug OK aislado | 6/6 OK | Automático | Suite completa afectada por cambios concurrentes |
| 30/07/2026 | D19 | Win32 Debug OK | 2.188 inventariados | Automático | 3 recursos VCL condicionales no existen en Win32 |
| 30/07/2026 | D20 | Win32 Debug OK | 2.902 claves sincronizadas | No ejecutado | BBDD central actualizada |
| 30/07/2026 | D21 | `utlTraduc` Win32 Debug OK | 6.863/6.863; 0 pendientes | No ejecutado | Traducción automática pendiente de revisión visual |
| 30/07/2026 | D22-A | No aplica | 300 literales de 23 informes | No ejecutado | BLOB personalizados pendientes |
| 30/07/2026 | D22-B | Pendiente | 300 en-GB; traducción por texto | No ejecutado | Compilación y revisión visual pendientes |
| 30/07/2026 | D23 | Pendiente | 7.163 ca-ES; 0 pendientes | No ejecutado | Compilación, SQL y revisión visual pendientes |
| 30/07/2026 | R01 | Pendiente | 13 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R02 | Pendiente | 25 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R03 | Pendiente | 16 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R04 | Pendiente | 9 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R05 | Pendiente | 49 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R06 | Pendiente | 15 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R07 | Pendiente | 19 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R08 | Pendiente | 24 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R09 | Pendiente | 37 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R10 | Pendiente | 61 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R11 | Pendiente | 28 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R12 | Pendiente | 47 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R13 | Pendiente | 25 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R14 | Pendiente | 10 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R15 | Pendiente | 52 revisados; 0 pendientes | No ejecutado | Ninguna |
| 30/07/2026 | R16 | Pendiente | 2 revisados; 0 pendientes | No ejecutado | Ninguna |

## Criterio de finalización

El proyecto se considerará preparado para incorporar un segundo idioma cuando:

- Todas las tandas M y R estén en estado `PROBADO`.
- D01 esté implementada y las tandas D estén probadas con pseudoidioma.
- No haya literales visibles directos en código propio del ejecutable.
- El idioma español reproduzca los textos y flujos actuales.
- Un segundo catálogo pueda cargarse sin recompilar formularios.
- Win32 y Win64 compilen sin nuevos warnings.

