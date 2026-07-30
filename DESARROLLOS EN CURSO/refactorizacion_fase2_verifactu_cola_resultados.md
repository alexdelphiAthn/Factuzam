# Fase 2 — `inLibVerifactuCola` tras contrato

Fecha: 30/07/2026.

Estado: **VFC-R3 IMPLEMENTADA; PRUEBAS AMPLIADAS Y EJECUTADAS**. La
batería DUnitX compila y supera las pruebas en ambas plataformas. El
trinquete global de tamaño conserva regresiones concurrentes sin elevar
topes.

## 1. Línea base

`src/verifactu/inLibVerifactuCola.pas` reunía:

- 1.343 líneas;
- 26 sentencias SQL literales: 2 `SELECT`, 4 `INSERT`, 18 `UPDATE` y
  2 `CALL`;
- seis operaciones públicas acopladas a `TUniQuery` o
  `TUniConnection`;
- el encolado fiscal, NO VERI*FACTU, rectificativas, relaciones,
  reclamación de pendientes, reintentos y el hilo en segundo plano.

El trinquete SQL no recorría `src/verifactu`, por lo que este foco no
aparecía en el total vigente aunque siguiera hablando UniDAC y SQL.

## 2. Resultado de la tanda

Estado tras VFC-R3:

| Pieza | Líneas | Rutinas | SQL | Responsabilidad |
|---|---:|---:|---:|---|
| `inLibVerifactuTipos` | 25 | 0 | 0 | tipos fiscales puros |
| `inLibVerifactuColaIntf` | 60 | 0 | 0 | puertos de servicio y procesador |
| `inLibVerifactuCola` | 206 | 9 | 0 | fachada inyectable |
| `UniDataVerifactuColaRepositorio` | 282 | 20 | 3 | encolado con envío y modo sin Verifactu |
| `UniDataVerifactuColaProcesador` | 417 | 17 | 4 | worker y conexión propia |
| `UniDataVerifactuColaResultados` | 317 | 5 | 8 | consolidación y reintentos |
| `UniDataVerifactuColaOperaciones` | 509 | 14 | 11 | NO VERI*FACTU, rectificativas y relaciones |

La fachada y su contrato no importan `Uni`, `Data.DB`, `UniData*`,
datasets ni módulos de datos. Los consumidores construyen el adaptador
en sus límites de composición y lo entregan como
`IServicioVerifactuCola`.

El hilo también entra por `IProcesadorVerifactuCola`; la fachada no
crea conexiones ni conoce `TThread`. Desde VFC-R1 el repositorio tampoco
conoce el hilo: cada procesador posee y libera su worker.

Se han actualizado los consumidores de:

- estrategias de emisión fiscal;
- caja;
- formulario principal;
- mantenimiento y consulta de facturas;
- rectificativas;
- sustitución de tickets;
- borrado de facturas.

## 3. Pruebas sin BBDD

`PruebasVerifactuColaRepositorio` comenzó con once casos sin BBDD:

1. delegación completa del encolado;
2. registro NO VERI*FACTU;
3. datos de una rectificativa;
4. relación fiscal con su origen;
5. fallo ruidoso si no se inyecta el servicio;
6. inicio y parada únicos del procesador;
7. rechazo de una factoría UniDAC sin servicio de conexiones;
8. espera exponencial con techo;
9. transición a error al agotar los intentos;
10. estado del registro NO VERI*FACTU según la operación;
11. fallo ruidoso de la rectificativa sin servicio de emisión.

La ampliación final añade diez casos:

12. delegación completa del marcado transitorio sin Verifactu;
13. delegación del borrado de movimientos con serie y número;
14. conservación del primer procesador y parada idempotente;
15. rechazo de un procesador nulo;
16. rechazo de una consulta UniDAC nula;
17. rechazo de una consulta UniDAC sin conexión;
18. rechazo de una conexión UniDAC nula;
19. construcción correcta del adaptador por consulta y por conexión;
20. saturación del backoff en el quinto intento;
21. transición a error desde el primer intento cuando el máximo es uno.

Los 21 casos no abren conexiones ni requieren BBDD. La ejecución Release
Win32 y Win64 incluye la compilación explícita de los cuatro adaptadores
UniDAC:

```text
Tests Found   : 396
Tests Ignored : 0
Tests Passed  : 396
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

Antes de la ampliación la misma batería global encontraba 386 pruebas;
las diez nuevas explican exactamente el paso a 396.

## 4. Trinquetes ejecutados antes de compilar

Salida de `scripts/comprobar_sql_en_dominio.ps1`:

```text
SQL en dominio: OK. Sentencias literales: 317.
Unidades con SQL: 65.
```

El script vigila ahora explícitamente
`src/verifactu/inLibVerifactuCola.pas`. Se conserva el tope concurrente
317/65 fijado por SQL-2.3d; no se ha actualizado al alza.

Medición específica con el mismo analizador:

```text
inLibVerifactuCola                         0 sentencias
UniDataVerifactuColaRepositorio           26 sentencias
```

`comprobar_tamano_clases.ps1` vigila las seis unidades de la tanda:

- fachada: tope 206/9, objetivo 600/30, alcanzado;
- contrato: tope 60/0, objetivo 600/30, alcanzado;
- tipos: tope 25/0, objetivo 600/30, alcanzado;
- repositorio: tope 881/36, objetivo 1.200/30, pendiente solo por
  rutinas;
- procesador: tope 417/17, objetivo 800/20, alcanzado;
- resultados: tope 317/5, objetivo 900/25, alcanzado.

El script global de tamaño no termina actualmente por crecimiento
concurrente en clases ajenas. La salida varía mientras avanzan las
tandas paralelas; en la ejecución de VFC-R2 muestra, entre otras:

```text
TfrmMtoComprasSesiones  3.669 > 3.659
TfrmMtoFacturasBase     4.005 > 4.000
TfrmMtoOpeCaja          4.061 > 4.060
TfrmStockConsulta       3.141 > 3.139
TGridPivoteVenta          946 > 944
TPresentacionPivoteVenta 1.134 > 1.131
TVistaPivoteVenta          294 > 290
```

La inyección añadida a `TfrmMtoFacturasBase` se dejó sin crecimiento
físico propio; las líneas restantes proceden de la tanda concurrente.
No se ha elevado ningún tope.

## 5. Crecimiento y plan de reducción

La frontera fiscal pasa de una unidad de 1.343 líneas a 1.906 líneas de
producción entre fachada, contrato, tipos y adaptadores: **+563 líneas**.
El crecimiento se debe a conservar temporalmente la implementación
fiscal y añadir la frontera inyectable sin alterar su comportamiento.
VFC-R1 reduce cinco líneas respecto a la primera separación. VFC-R2
baja de 1.620 a 1.615 líneas conjuntas entre repositorio, procesador y
resultados: separa responsabilidad y reduce cinco líneas netas. VFC-R3
baja el conjunto de 1.615 a 1.525 líneas al eliminar la doble capa
interna: reduce noventa líneas netas. Todas las unidades quedan por
debajo de 1.200 líneas y de 30 rutinas.

El tope del adaptador queda congelado y se reducirá en estas tandas:

1. **VFC-R1 — procesador de cola, terminada.** Conexión de segundo
   plano, reclamación, espera y ciclo de vida extraídos a
   `UniDataVerifactuColaProcesador`: 739 líneas y 19 rutinas.
2. **VFC-R2 — persistencia de resultados, terminada.** Consolidación,
   cadena, fase y reintentos separados en
   `UniDataVerifactuColaResultados`: 317/5.
3. **VFC-R3 — operaciones sin envío, terminada.** NO VERI*FACTU,
   rectificativas, relaciones y reversión de movimientos separados en
   `UniDataVerifactuColaOperaciones`: 509/14. La doble capa interna
   estática más adaptador queda eliminada.
4. **VFC-R4 — cierre.** Revalidación conjunta de métricas y baterías
   fiscales en Release Win32 + Win64. Los límites de 1.200 líneas y
   30 rutinas ya se cumplen en todas las unidades resultantes.

Cada reducción bajará su tope en
`scripts/comprobar_tamano_clases.ps1`; nunca lo elevará para hacer pasar
el script.

## 6. Compilación anterior a VFC-R1

Resultado final:

```text
FactuzamTests Release Win32: compilado, 318/318
FactuzamTests Release Win64: compilado, 318/318
fzam Release Win32: compilado, 339.618 líneas
fzam Release Win64: compilado, 339.618 líneas
```

Las baterías completas incluyen `PruebasEmisionFiscal`,
`PruebasRectificativas` y `PruebasVerifactuColaRepositorio`.

La revalidación conjunta se aplaza hasta que termine la tanda
concurrente de traducciones. El bloqueo observado antes de iniciar
VFC-R1 fue:

```text
FactuzamTests Release Win32:
  F2613 Unit 'inLibMsgRegistroTraducciones' not found
```

El archivo pertenece a la tanda concurrente y no se ha recreado ni
alterado desde Verifactu.

## 7. Resultado VFC-R1

La factoría `CrearProcesadorVerifactuColaUniDAC` sale del repositorio y
la composición principal importa `UniDataVerifactuColaProcesador`.
Desaparecen del repositorio `TThread`, el estado global del hilo y las
dependencias de conexión/sesión necesarias solo para el worker.

Distribución SQL medida con el analizador del trinquete:

```text
UniDataVerifactuColaRepositorio  14 sentencias
UniDataVerifactuColaProcesador   12 sentencias
Total                            26 sentencias
```

Salidas ejecutadas antes de la compilación aplazada:

```text
SQL en dominio: OK. Sentencias literales: 317. Unidades con SQL: 65.
Dependencias de capa: OK. Unidades analizadas: 467. Ciclo mayor: 1.
SQL, transacciones y eventos críticos: OK.
Estado global: OK. Variables var en interface: 0. Except vacíos: 0.
```

La tabla de unidades del control de tamaño muestra:

```text
UniDataVerifactuColaProcesador  739/19  objetivo 800/20  ALCANZADO
UniDataVerifactuColaRepositorio 881/36  objetivo 1200/30 PENDIENTE
```

El fallo global del script sigue limitado a los cuatro formularios
concurrentes ya enumerados. Los topes Verifactu bajan de 1.625/67 a
881/36 y se añade 739/19 para el procesador; ninguno se eleva.

Se añade una séptima prueba sin BBDD para exigir que la factoría del
procesador rechace dependencias ausentes. Queda incluida y ejecutada en
la batería final.

## 8. Resultado VFC-R2

`UniDataVerifactuColaProcesador` conserva reclamación, envío,
transacción y control de flujo. Delega la persistencia posterior en
`TResultadosVerifactuColaUniDAC`, que concentra:

- avance de la cadena de huellas;
- alta, anulación y subsanación de consolidaciones;
- fase fiscal y estado de cola;
- backoff, agotamiento de intentos y eventos fiscales.

Distribución SQL:

```text
UniDataVerifactuColaRepositorio  14 sentencias
UniDataVerifactuColaProcesador    4 sentencias
UniDataVerifactuColaResultados    8 sentencias
Total                            26 sentencias
```

La extracción reduce código:

```text
Antes de VFC-R2: procesador             739 líneas
Después:        procesador + resultados 417 + 317 = 734 líneas
```

Salidas ejecutadas antes de la compilación aplazada:

```text
SQL en dominio: OK. Sentencias literales: 304. Unidades con SQL: 64.
Dependencias de capa: OK. Unidades analizadas: 474. Ciclo mayor: 1.
SQL, transacciones y eventos críticos: OK.
Estado global: OK. Variables var en interface: 0. Except vacíos: 0.
UniDataVerifactuColaProcesador 417/17 objetivo 800/20 ALCANZADO
UniDataVerifactuColaResultados 317/5  objetivo 900/25 ALCANZADO
```

Los topes del procesador bajan de 739/19 a 417/17 y la nueva unidad
queda vigilada en 317/5. Se añaden dos pruebas puras para el backoff y
la transición a error; quedan incluidas y ejecutadas en la batería
final.

## 9. Resultado VFC-R3

Las operaciones sin envío a AEAT salen del repositorio a
`UniDataVerifactuColaOperaciones`: el registro NO VERI*FACTU con toda
su persistencia (cadena, consolidación y fase), las rectificativas,
las relaciones fiscales y la reversión de movimientos que comparten
ambos caminos.

Desaparece la doble capa interna: la clase estática
`TVerifactuColaUniDAC` se elimina y `TServicioVerifactuColaUniDAC`
implementa el contrato directamente sobre su consulta y conexión. El
encolado con envío y el modo transitorio sin Verifactu quedan como
única lógica propia del repositorio; el resto delega en la unidad de
operaciones. Ningún consumidor usaba la clase estática: todos entran
por `CrearServicioVerifactuColaUniDAC`, que no cambia de firma.

Distribución SQL medida con el analizador del trinquete:

```text
UniDataVerifactuColaRepositorio   3 sentencias
UniDataVerifactuColaProcesador    4 sentencias
UniDataVerifactuColaResultados    8 sentencias
UniDataVerifactuColaOperaciones  11 sentencias
Total                            26 sentencias
```

La extracción reduce código:

```text
Antes de VFC-R3: repositorio               881 líneas
Después:        repositorio + operaciones  282 + 509 = 791 líneas
```

Los topes del repositorio bajan de 881/36 a 282/20 y alcanzan su
objetivo 1.200/30; la unidad nueva queda vigilada en 509/14 con
objetivo 900/25. Ningún tope se eleva. La unidad nueva se registra en
`fzam.dpr` y `FactuzamTests.dpr`.

Se añaden dos pruebas sin BBDD: el estado del registro NO VERI*FACTU
según la operación (`ObtenerEstadoRegistroNoVerifactu`) y el fallo
ruidoso de la rectificativa sin servicio de emisión. Quedan incluidas y
ejecutadas en la batería final.
