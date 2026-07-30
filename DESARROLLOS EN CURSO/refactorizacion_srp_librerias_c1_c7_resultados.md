# C1-C7 — materialización de sesiones de compra (resultados)

Fecha: 30/07/2026. Fascículos C1 a C7 implementados. Sin commit.

## Resultado

`UniDataComprasSesionesMaterializar` deja de contener el caso de uso
completo. Pasa de **3.042 líneas y 75 rutinas** a una fachada de
persistencia de **189 líneas y 12 rutinas**. El flujo queda repartido
por responsabilidad:

| Unidad | Líneas | Rutinas | Responsabilidad |
|---|---:|---:|---|
| `inLibComprasSesionesMaterializar` | 300 | 10 | orquestación pura |
| `inLibComprasSesionesMaterializacionIntf` | 75 | 0 | puertos |
| `UniDataComprasSesionesMaterializar` | 189 | 12 | fachada UniDAC |
| `UniDataComprasSesionesArticulos` | 1.091 | 26 | artículos, SKU y EAN13 |
| `UniDataComprasSesionesAlbaranes` | 638 | 9 | albaranes |
| `UniDataComprasSesionesPedidos` | 770 | 12 | pedidos y pendientes |
| `UniDataComprasSesionesReversion` | 359 | 12 | reversión |
| `UniDataComprasSesionesEstado` | 221 | 7 | sesión, series y almacenes |
| `UniDataComprasSesionesDocumentosComun` | 83 | 1 | lectura común de líneas |
| `UniDataComprasSesionesUnidadTrabajo` | 141 | 10 | transacción UniDAC |
| `UniDataComprasSesionesComposicion` | 72 | 1 | composición |

Todas las unidades resultantes quedan por debajo de 1.200 líneas y
30 rutinas. La fachada y el orquestador quedan además por debajo del
objetivo 600/30.

El repositorio general ya no publica `EjecutarMaterializacion` ni
`RevertirMaterializacion`. `TServicioComprasSesiones` construye los dos
casos de uso sobre contratos y el formulario solo conserva diálogo,
mensajes, navegación, foco y refresco.

## Comportamiento fijado

Las pruebas sin BBDD caracterizan:

- documento único y uno por almacén;
- pedido, albarán y ambos;
- materialización de artículos una sola vez en el modo por almacén;
- caso sin almacenes efectivos;
- orden y primer documento del resultado;
- resultado parcial y mensaje de error;
- rollback después de una escritura;
- reintento tras fallo;
- confirmación única del caso de uso;
- rollback de reversión;
- reutilización de una transacción ya activa.

La reversión ya no elimina artículos, propiedades, tarifas, SKU,
atributos, fotos ni EAN13. Solo revierte documentos, movimientos,
pendientes de recibir y estado de la sesión. Las tablas opcionales se
siguen consultando una vez y un fallo real no se silencia.

## Transacción

`IUnidadTrabajoMaterializacion` delimita el caso de uso. Los adaptadores
de artículos, documentos, estado y reversión no hacen commit ni rollback.
El adaptador UniDAC registra si creó la transacción:

- si la creó, confirma o revierte;
- si recibió una transacción activa, no la confirma ni la revierte;
- un fallo intermedio vuelve por el mismo puerto y deja un único punto
  de rollback.

## Balance de código y plan de reducción

La separación añade contratos, orquestación, composición y dobles. Las
11 unidades vigiladas suman **3.939 líneas físicas**, frente a las
3.042 de la antigua unidad: **+897 líneas**. No se presenta esta subida
como reducción; es coste arquitectónico visible y queda con un plan
medible:

1. **R1 — retirar la fachada temporal.** Hacer que los adaptadores
   especializados implementen puertos segregados y eliminar
   `UniDataComprasSesionesMaterializar`. Objetivo: -120 líneas.
2. **R2 — contexto de persistencia único.** Cargar una vez serie,
   número, empresa, proveedor, tarifa y temporada, evitando repetir
   lecturas de campos en artículos, pedido y albarán. Objetivo:
   -120 líneas.
3. **R3 — parametrización común de documentos.** Compartir únicamente
   el mapeo tipado de línea y parámetros, manteniendo SQL separado para
   pedido y albarán. Objetivo: -140 líneas.
4. **R4 — compactar comentarios históricos y código muerto.** Conservar
   solo decisiones vigentes y eliminar explicaciones de implementaciones
   ya sustituidas. Objetivo: -80 líneas.

Primer objetivo acumulado: **3.479 líneas o menos** sin subir ningún
tope. Segundo objetivo: recuperar **3.042 líneas o menos** mediante
reducciones posteriores justificadas, no comprimiendo SQL ni relajando
el ancho de 80 columnas.

## Salida del trinquete previa a compilación

Comando:

```powershell
.\scripts\comprobar_tamano_clases.ps1
```

Salida de las unidades y clases afectadas:

```text
TfrmMtoComprasSesiones
  ActualLineas=3659  TopeAnteriorLineas=3659
  ActualMetodos=99   TopeAnteriorMetodos=99
  EstadoObjetivo=PENDIENTE

UniDataComprasSesionesAlbaranes
  ActualLineas=638   TopeAnteriorLineas=638
  ActualRutinas=9    TopeAnteriorRutinas=9    EstadoObjetivo=ALCANZADO
UniDataComprasSesionesArticulos
  ActualLineas=1091  TopeAnteriorLineas=1091
  ActualRutinas=26   TopeAnteriorRutinas=26   EstadoObjetivo=ALCANZADO
UniDataComprasSesionesComposicion
  ActualLineas=72    TopeAnteriorLineas=72
  ActualRutinas=1    TopeAnteriorRutinas=1    EstadoObjetivo=ALCANZADO
UniDataComprasSesionesDocumentosComun
  ActualLineas=83    TopeAnteriorLineas=83
  ActualRutinas=1    TopeAnteriorRutinas=1    EstadoObjetivo=ALCANZADO
UniDataComprasSesionesEstado
  ActualLineas=221   TopeAnteriorLineas=221
  ActualRutinas=7    TopeAnteriorRutinas=7    EstadoObjetivo=ALCANZADO
UniDataComprasSesionesMaterializar
  ActualLineas=189   TopeAnteriorLineas=189   ObjetivoLineas=600
  ActualRutinas=12   TopeAnteriorRutinas=12   ObjetivoRutinas=30
  EstadoObjetivo=ALCANZADO
UniDataComprasSesionesPedidos
  ActualLineas=770   TopeAnteriorLineas=770
  ActualRutinas=12   TopeAnteriorRutinas=12   EstadoObjetivo=ALCANZADO
UniDataComprasSesionesReversion
  ActualLineas=359   TopeAnteriorLineas=359
  ActualRutinas=12   TopeAnteriorRutinas=12   EstadoObjetivo=ALCANZADO
UniDataComprasSesionesUnidadTrabajo
  ActualLineas=141   TopeAnteriorLineas=141
  ActualRutinas=10   TopeAnteriorRutinas=10   EstadoObjetivo=ALCANZADO
inLibComprasSesionesMaterializacionIntf
  ActualLineas=75    TopeAnteriorLineas=75
  ActualRutinas=0    TopeAnteriorRutinas=0    EstadoObjetivo=ALCANZADO
inLibComprasSesionesMaterializar
  ActualLineas=300   TopeAnteriorLineas=300   ObjetivoLineas=600
  ActualRutinas=10   TopeAnteriorRutinas=10   ObjetivoRutinas=30
  EstadoObjetivo=ALCANZADO

Tamano de clases: OK. Clases analizadas: 384.
Maximos: 4060 lineas, 133 metodos y 49 campos F*.
Unidades procedurales vigiladas: 11.
```

La entrada antigua se ha sustituido por las 11 unidades resultantes.
Cada tope de no regresión coincide con la medida actual; los objetivos
siguen siendo 600/30 para fachada y orquestador, y 1.200/30 para cada
unidad especializada.

## Verificación

- Release Win32: compilado.
- Release Win64: compilado.
- DUnitX Debug Win32: 307/307.
- DUnitX Debug Win64: 307/307.
- dependencias de capa: OK, ciclo mayor 1;
- SQL en dominio: 331 sentencias en 66 unidades, OK;
- SQL/transacciones: 115 literales fijos, 3 identificadores con lista
  blanca y 0 valores externos concatenados, OK;
- flujos largos: materializador 38 líneas, revertidor 22, OK;
- estado global, formularios delgados, `Supports` y acoplamiento: OK.
