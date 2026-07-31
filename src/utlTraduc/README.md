# Editor de traducciones

`utlTraduc` es una aplicación VCL independiente para editar los idiomas del
catálogo `fza_traducciones`.

## Uso

1. Comprobar la ruta del INI de Factuzam.
2. Conectar y elegir el idioma de destino.
3. Pulsar `Sincronizar español` para importar los textos compilados.
4. Cargar todas las claves o solamente las pendientes.
5. Seleccionar una clave, editar su traducción y guardar los cambios.

El guardado se realiza en una sola transacción mediante
`INSERT ... ON DUPLICATE KEY UPDATE`. Antes de escribir se comprueba que la
traducción no esté vacía y que conserve los marcadores de `Format`.

La utilidad lee por defecto `%LOCALAPPDATA%\factuzam\fzam.ini`, incluida la
contraseña cifrada `PasswordEn`. Se puede seleccionar otro INI o pasarlo como
primer parámetro de línea de comandos. No guarda credenciales ni modifica el
esquema. Requiere que `DESARROLLOS EN CURSO/traducciones.sql` ya esté aplicado.

## Catálogo central

`fza_traducciones` es el único catálogo consultado en ejecución. Contiene
los textos de formularios, los `resourcestring` propios, los de la VCL y las
claves de Developer Express. Los recursos compilados no forman un catálogo
paralelo: sólo permiten sembrar el español y conservar un respaldo si no se
puede leer la BBDD.

El registro
`src/Lib/inLibRegistroResourcestringTraducciones.pas` enlaza cada clave
`unidad.identificador` con su `resourcestring`. Incluye las unidades
`inLibMsg*` y `src/vcl37/Vcl.Consts.pas`. Se regenera mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_registro_resourcestring.ps1'
```

La importación actualiza `es-ES` mediante `INSERT ... ON DUPLICATE KEY UPDATE`
y no modifica las unidades de origen. Las claves de Developer Express usan
el prefijo `DevExpress.` y se obtienen de `CXLOCALIZATION.res`, incluidas las
personalizaciones de la hoja de cálculo.

Las categorías y descripciones creadas en ejecución por los inspectores de
Parámetros Generales y Parámetros de Caja se registran en
`src/Lib/inLibRegistroParametrosTraducciones.pas`. El registro se regenera
desde las llamadas `RegistrarParametro` mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_registro_parametros_traduccion.ps1'
```

El selector de destino carga los idiomas activos de la BBDD al conectar. El
combo admite también escribir una etiqueta nueva, por ejemplo `fr-FR`, para
crear otro idioma sin modificar `utlTraduc`.

Los rótulos de tickets térmicos viven en
`src/Lib/inLibMsgTickets.pas`. Se importan con `Sincronizar español` igual que
el resto de `resourcestring`. La propuesta catalana y su SQL idempotente se
regeneran mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_traducciones_tickets.ps1'
```

El resultado es
`DESARROLLOS EN CURSO/traducciones_ca_es_tickets_d24.sql`. Para otro idioma,
se selecciona o escribe su etiqueta en `utlTraduc` y se completan las mismas
claves `inLibMsgTickets.*`, sin modificar los generadores de ticket.

En sentido inverso, Factuzam consulta la BBDD cuando evalúa un
`resourcestring`, carga un formulario o solicita un texto de Developer
Express. Si no hay conexión, clave o traducción activa, conserva el texto
compilado como respaldo. No se aplica ninguna traducción española de
Developer Express al margen de `fza_traducciones`.

## Informes FastReport

Las plantillas predeterminadas no están en ficheros `.fr3`: se guardan como
`TfrxReport` dentro de los DFM. Sus textos `Memo.UTF8W` se exportan con:

```powershell
& '.\DESARROLLOS EN CURSO\generar_traducciones_fastreport.ps1'
```

El resultado idempotente se guarda en
`DESARROLLOS EN CURSO/traducciones_d22_fastreport.sql`. Las claves usan
`FastReport.<unidad>.Predeterminado.<objeto>.Memo` y conservan las expresiones
`[DataSet]` del informe. Los formatos personalizados guardados como BLOB en
`fza_usuarios_perfiles` forman la subfase D22-B y no se mezclan con las
plantillas predeterminadas.

## Compilación

Abrir `utlTraduc.dproj` o compilar las configuraciones Win32/Win64 desde
Delphi. Los binarios se generan bajo `bin/<plataforma>/<configuración>`.
