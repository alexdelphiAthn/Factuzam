# Informe de pruebas — Fase XII-D

Fecha: 25/07/2026

## Resultado

La retirada de los alias globales de parámetros está completada. Los
controles estructurales, la regresión unitaria y la matriz de
compilación Delphi son correctos.

La validación funcional interactiva se ha ejecutado contra la BBDD
`Factuzam` de `127.0.0.1:3306`. Los puntos 1 a 4 son correctos. Durante
esa validación apareció un defecto de contador de referencias en la
factoría de parámetros de aplicación, ajeno al alcance mecánico de la
fase pero introducido por el motor nuevo; está corregido y verificado.
Los puntos 5 a 8 quedan pendientes.

## Cierre estructural

- 0 apariciones de `oAppParams` / `oCajaParams` en `src`.
- 0 funciones libres `TarifaDefecto` / `NivelesFamiliaArqueo`.
  Ambas operaciones solo existen como métodos de `IParametrosCaja`.
- 0 consumidores dependientes de `inLibAppParam` /
  `inLibCajaParam`. La raíz usa las factorías de ambas unidades.
- La raíz conserva los servicios mediante `AsignarParametros` y los
  libera antes que `TdmPerfiles`.
- Las implementaciones continúan registradas en `fzam.dpr` y
  `fzam.dproj`.
- El patrón de consumo está documentado en
  `LIBRO_DE_ESTILO_DELPHI.md` §14.
- `factuzam_original.sql` permanece intacto.

## Comprobación de obsolescencia

Antes de retirar las declaraciones se marcaron temporalmente como
`deprecated`. La compilación Debug Win64 terminó con:

- 0 errores;
- 110 avisos, iguales a la línea base;
- 0 avisos de uso `deprecated`.

Después de esta comprobación se eliminaron las declaraciones.

## Pruebas automáticas

`ejecutar_pruebas.ps1`:

- regresión estructural XII-C: correcta;
- estructura específica XII-D: correcta;
- prueba unitaria del motor Win32: correcta;
- prueba unitaria del motor Win64: correcta.

`ejecutar_compilacion.ps1`, con Studio 37.0:

| Configuración | Resultado | Errores | Avisos | Deprecated |
|---|---:|---:|---:|---:|
| Debug Win64 | Correcta | 0 | 110 | 0 |
| Release Win32 | Correcta | 0 | 107 | 0 |
| Release Win64 | Correcta | 0 | 109 | 0 |

Los avisos coinciden con la línea base de XII-A, XII-B y XII-C.

Atención al alcance de este script: compila a un directorio temporal
bajo `%TEMP%` y borra los artefactos al terminar, de modo que **no**
actualiza `Win64\Release\fzam.exe`. Antes de cualquier prueba
funcional hay que compilar aparte con la salida por defecto del
proyecto; para eso se añade `compilar_release_win64.cmd`, que invoca
`rsvars.bat` y `msbuild` con `Config=Release` y `Platform=Win64` y deja
el resultado en `resultado_build_release_win64.txt`.

## Defecto detectado y corregido

Síntoma: «Otros → Parámetros del entorno» (`TfrmMtoAppParam`) construía
el inspector con las 30 definiciones del catálogo de Caja en vez de las
49 de aplicación, todas con su valor por defecto. El editor de Caja
mostraba las suyas correctamente. Además la aplicación arrancaba con el
tema `Office2007Pink` de respaldo en lugar del configurado, y la
ventana del editor dejaba de responder al botón de cierre.

Causa: `TParametrosAplicacion.DespuesDeRecargar` ejecuta
`AplicarModosDepuracion(Self as IParametrosAplicacion)`. Ese `Self as`
crea una referencia de interfaz temporal sobre un `TInterfacedObject`
cuyo contador está todavía a cero, porque la factoría llamaba a
`InicializarParametrosApp` —y por debajo a `Inicializar`, `Recargar` y
el hook— sosteniendo solo una referencia de objeto. Al soltar la
temporal el contador baja de 1 a 0 y el objeto se autodestruye durante
su propia construcción. La factoría devolvía un puntero colgante y, al
crearse acto seguido `TParametrosCaja`, del mismo tamaño, el gestor de
memoria reutilizaba el bloque recién liberado: `ParametrosApp` y
`ParametrosCaja` pasaban a ser el mismo objeto, el de caja. Como
`TParametrosCaja` no sobrescribe el hook, era el superviviente.

Corrección, en `inLibAppParam.CrearParametrosAplicacion`: asignar
`Result := Parametros` **antes** de inicializar, para que el interfaz
gobierne la vida del objeto y la referencia temporal del hook vaya de 1
a 2 y vuelva a 1. Con el interfaz gobernando, el `try/except` con
`FreeAndNil` sobra y sería una doble liberación: si la inicialización
lanza, el compilador finaliza `Result` y libera correctamente. Se
aplica el mismo orden en `inLibCajaParam.CrearParametrosCaja` por
simetría y para prevenir el mismo error si algún día se añade un hook
equivalente.

Verificación con trazas temporales, ya retiradas: antes de la
corrección el editor recibía 30 definiciones; después, `DIAG raiz:
appEdicion=49 cajaEdicion=30` y `DIAG editor App: definiciones=49`. En
pantalla el editor pasa a mostrar el catálogo de aplicación con sus
valores guardados y la aplicación arranca con el tema `Caramel`
configurado. La compilación tras la corrección conserva la línea base:
0 errores y 109 avisos en Release Win64.

## Validación funcional — puntos 1 a 4

Entorno: BBDD `Factuzam` en `127.0.0.1:3306`, usuario de aplicación
Administrador (grupo Administradores, grupo raíz), binario Release
Win64 compilado del árbol de trabajo con la corrección aplicada.

1. **Arranque, sesión y cierre.** Correcto. Autologin, conexión
   establecida y menú principal. El log de arranque no registra
   errores. Al cerrar, la aplicación guarda su `fzam.ini` y termina.

2. **Los dos editores.** Correcto. Aplicación: 49 parámetros en
   Apariencia, Arranque, Consulta de Stock, Directorios, Fotos,
   Impresión, Log, Seguridad, Servicios web, Valores por defecto y
   Verifactu. Caja: 30 parámetros en sus diez categorías. Ambos
   recuentos cuadran con los catálogos del código.

3. **Persistencia por tipos.** Correcta en los dos editores y en los
   tres tipos. En aplicación se editaron `appLogSQL` (booleano),
   `appVentasWsSegundosCiclo` (entero) y `appImpresoraInformes`
   (cadena); en caja, «Agrupar unidades iguales», «Número de
   operaciones pendientes» y el texto del aviso de artículos sin
   stock. En ambos casos se guardó, se cerró, se reabrió y los valores
   seguían aplicados. Todos revertidos después a su valor original,
   comprobado también por consulta directa a `fza_usuarios_perfiles`.

4. **Recarga en caliente del log.** Correcta en los dos sentidos y sin
   reiniciar. Al guardar `appLogSQL = True` el log registra `Modos log
   aplicados: ... appLogSQL=True` y a continuación aparecen las trazas
   SQL, empezando por las del hilo de la cola Verifactu, lo que además
   confirma que ese hilo lee parámetros por interfaz. Al devolverlo a
   False las trazas cesan.

5. **Parámetros huérfanos.** Correcto. Insertada a mano en
   `fza_usuarios_perfiles` la subclave `appClaveHuerfanaXIID` para
   `frmMtoAppParam` / Administrador, aparece en el editor bajo «Otros
   (Heredados de BD)» como «Parámetro sin descripción» con su valor.
   Clave eliminada al terminar; comprobado que no queda ninguna.

También se verificó que el botón de cierre del editor funciona con
normalidad en el binario corregido. Los fallos de cierre observados
antes eran otro síntoma del objeto liberado, no un defecto aparte.

## Observaciones

**El huérfano exige una recarga real.** La clave añadida a mano solo
aparece cuando el servicio vuelve a cargar su perfil, es decir al
arrancar la aplicación o al guardar con cambios en el editor. Pulsar
Guardar sin cambios responde «No se detectaron cambios para guardar» y
no dispara `Recargar`. Es coherente con la implementación, pero hay que
tenerlo presente al repetir la prueba: sin reinicio ni guardado
efectivo, el huérfano no se ve y la prueba parece fallar.

**La carga inicial trabaja con la caché fría.** Los dos servicios de
parámetros se crean antes de `PrecargarCachesSerie`, así que su
`Recargar` inicial encuentra `FCachePrecargada = False`. El log lo deja
por escrito en cada arranque:

```
Arranque: creando parámetros de aplicación
WARNING: ResincronizarCachePerfilForm: form="frmMtoAppParam" cache no
         precargado, ignorado
WARNING: ObtenerPerfilFormCache: form="frmMtoAppParam" cache NO
         precargado (FCachePrecargada=False), devuelve False
```

y lo mismo para `frmMtoCajaParam`. El resultado es correcto porque
`CargarPerfilFormulario` cae a `CargarPerfilFormDesdeDB`, pero cada
arranque paga dos consultas directas a BBDD y dos avisos que no son
tales. Conviene decidir si se adelanta la precarga de perfiles a antes
de crear los servicios o si se degradan esos avisos a informativos.

## Pendiente

Puntos 5 a 8 de la batería: caja completa (tarifa por defecto, venta,
vale, devolución y arqueo con desglose de familias), impresión de PDF,
Excel, tickets y tiras de caja, fotos locales y de nube, correo e
inventarios por API, y las colas Verifactu y ventas WS incluidos error
y reintento, con reloj fiscal y exportación NO VERI*FACTU.

No se ejecutan todavía porque escriben documentos persistentes en la
BBDD. La preparación está hecha y documentada en
`PLAN_PRUEBAS_5_8.md`, con `linea_base_5_8.sql` para capturar la foto
de partida y `limpieza_5_8.sql` para el borrado acotado posterior.

De esa preparación salen tres conclusiones que condicionan la
ejecución. La instalación tiene `appVerifactuActivo = True` y modo
`VERIFACTU`, así que cada venta firma y encadena su registro y no
existe limpieza que devuelva la BBDD a su estado anterior sin romper
la cadena; lo razonable es ejecutar sobre una copia y restaurarla. Los
puntos 7 y la parte de ventas WS del 8 están bloqueados por
configuración, porque el perfil no tiene URL, clave ni referencia de
instalación de la API. Y el reloj fiscal y la exportación NO
VERI*FACTU implican tráfico real contra el entorno de preproducción de
la AEAT y contra los servidores NTP, lo que hay que autorizar antes.

## Reproducción

- Pruebas: `ejecutar_pruebas.cmd`
- Matriz Delphi: `ejecutar_compilacion.cmd`
- Binario de pruebas: `compilar_release_win64.cmd`
