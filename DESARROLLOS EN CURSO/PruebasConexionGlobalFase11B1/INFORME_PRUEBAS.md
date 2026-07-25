# Informe de pruebas - Conexión global Fase XI-B1

Fecha: 25/07/2026

## Resultado

XI-B1 queda aplicada y validada en Windows. Las dos pantallas que
heredaban directamente de `TForm` pasan a `TfrmBase`, desaparecen sus
14 lecturas de `oConn` y la matriz Delphi compila sin errores.

## Alcance aplicado

| Unidad | Antes | Después | Refs retiradas |
| --- | --- | --- | ---: |
| `src/Forms/inMtoStockConsulta.pas` | `TForm` | `TfrmBase` | 13 |
| `src/Modals/inMtoModalFacturarAlbaranesFechas.pas` | `TForm` | `TfrmBase` | 1 |

Los dos DFM cambian únicamente su declaración raíz de `object` a
`inherited`, necesaria para la herencia visual de Delphi.

## Cambios de diseño

`TfrmStockConsulta` ya no declara copias privadas de:

- `FPermisos`;
- `FPerfilesUsuario`;
- `FContextoSesion`.

También se retiran el constructor de inyección y los tres métodos
asignadores duplicados. La pantalla consume ahora `Permisos`,
`PerfilesUsuario`, `ContextoSesion`, `IdentidadSesion` y
`ConexionPrincipal` desde `TfrmBase`.

La función `MostrarStockConsulta` queda reducida a:

```pascal
procedure MostrarStockConsulta(const ACodArt, ACodSku: string);
```

Los tres llamantes (`inMtoPrincipal`, `inMtoGen` e `inMtoCajaOpe`)
dejan de transportar permisos, perfiles y contexto. La instancia
continúa siendo propiedad de `Application`, por lo que conserva su
comportamiento persistente; `TfrmBase` obtiene los servicios del
formulario principal.

`TfrmModalFacturarAlbaranesFechas` obtiene la conexión del propietario
`TfrmMtoAlbaranes`, que ya implementa `IProveedorConexiones`.

Ambos `FormCreate` llaman primero a `inherited`, de modo que mantienen
la inicialización común de localización, etiquetas, teclado y servicios
de `TfrmBase`.

## Evolución de la conexión global

| Estado | Líneas | Apariciones | Unidades |
| --- | ---: | ---: | ---: |
| Tras XI-A | 179 | 183 | 38 |
| Tras XI-B1 | 165 | 169 | 36 |
| Reducción XI-B1 | 14 | 14 | 2 |

De las 68 apariciones asignadas originalmente a XI-B quedan 54 para
XI-B2, XI-B3 y XI-B4.

## Prueba estructural

Script: `PruebasConexionGlobalFase11B1.ps1`

Resultado: **13 comprobaciones, 13 correctas y 0 fallos**.

La barrera comprueba:

1. herencia Pascal de las dos clases;
2. herencia visual de los dos DFM;
3. ausencia de `oConn` en ambas unidades;
4. sustitución de las 14 lecturas originales por `ConexionPrincipal` y
   adaptación de las dos llamadas que reciben conexión explícita en XI-C;
5. ausencia de campos y constructor de inyección duplicados en stock;
6. simplificación del contrato `MostrarStockConsulta`;
7. encadenamiento de los dos `FormCreate`;
8. retirada del `uses inLibGlobalVar`;
9. cota global de 169 apariciones, 165 líneas y 36 unidades;
10. ancho máximo de 80 columnas en las líneas migradas;
11. conservación de los enlaces persistentes de los DFM;
12. limitación de cambios DFM a las dos raíces heredadas;
13. integridad de `factuzam_original.sql`.

## Compilación

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

El detalle está en `resultado_compilacion.txt`. Delphi conserva avisos
e indicaciones ya existentes en el proyecto; no aparece ningún error
nuevo asociado a XI-B1.

## Regresión automatizada

| Batería | Resultado |
| --- | ---: |
| Conexión global Fase XI-B1 | 13/13 |
| Conexión global Fase XI-A | 11/11 |
| Contexto de sesión Fase X-D | 11/11 |
| Contexto de sesión Fase X-C | 17/17 |
| Contexto de sesión Fase X-B | 13/13 |
| Contexto de sesión Fase X-A | 14/14 |
| Contexto de sesión Fase VIII | 18/18 |
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| **Total** | **134/134** |

Las barreras históricas de contexto, perfiles y XI-A se han adaptado
para reconocer la arquitectura final de XI-B1. Siguen rechazando
cualquier DFM adicional y continúan verificando los mismos contratos.

## Compatibilidad

- Se conservan los **253** enlaces persistentes
  `Connection = dmConn.conUni` de **52 DFM**.
- La consulta de stock conserva su instancia persistente propiedad de
  `Application` y el cierre sigue ocultándola mediante `caHide`.
- El modal conserva su creación con `Self` desde el mantenimiento de
  albaranes y recibe por ese propietario todos los servicios.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` permanece intacto.
- No se ha realizado ningún commit ni push.

## Prueba funcional recomendada

1. Abrir la consulta de stock con `Ctrl+U` desde un mantenimiento, desde
   caja y desde el menú principal.
2. Ocultarla con `Esc`, volver a abrirla y confirmar que conserva el
   modo de vista y carga el artículo/SKU activo.
3. Probar un usuario con y sin permiso de coste y comprobar la
   visibilidad de los datos correspondientes.
4. Probar búsqueda manual y lectura por código de barras en stock.
5. Desde albaranes, abrir «Facturar por fechas», buscar, marcar,
   desmarcar y generar borradores.
6. Confirmar visualmente que la localización y las etiquetas
   transparentes heredadas de `TfrmBase` no alteran el diseño.
