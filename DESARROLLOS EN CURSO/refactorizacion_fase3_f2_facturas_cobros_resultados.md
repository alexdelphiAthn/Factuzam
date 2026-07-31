# Fase 3, fascículo 2 — `inMtoFacturasBase`: presentación de cobros

Fecha: 31/07/2026. Sin commit.

**Estado de la tanda: VALIDADA.** `fzam` y `FactuzamTests` compilan en
Release Win32 y Win64. Las cuatro pruebas nuevas pasan en ambas
plataformas.

Esta es la primera costura del fascículo 2. Extrae la selección y
presentación de efectos/recibos. Las reglas fiscales y la consolidación
siguen siendo los siguientes cortes del formulario.

## 1. Qué se ha extraído

La nueva unidad
`src\Lib\inLibFacturasCobrosPresentacion.pas` concentra:

- la selección de `dsEfectosVenta` para facturas normales y
  `dsRecibos` para el resto;
- la edición, inserción, borrado y botones del navegador;
- los 19 nombres de campo de ambos orígenes;
- la visibilidad de las seis columnas de detalle;
- captions, texto plural y prefijo de exportación.

`CrearConfiguracionCobrosFactura` devuelve un record puro y comprobable
sin BBDD. `TPresentacionCobrosFactura` aplica ese record a los controles
DevExpress recibidos. No conoce el formulario ni el data module.

`TfrmMtoFacturasBase.AplicarOrigenCobros` conserva el cableado de sus
controles. La generación, impresión, cambio de estado y exportación
siguen en el formulario, pero reutilizan la misma configuración para no
repetir la decisión por tipo de factura.

## 2. Comportamiento conservado

| Tipo | Origen | Edición | Imprimir | Exportación |
|---|---|---:|---:|---|
| `NORMAL` | efectos de venta | no | oculto | `EfectosCobro_Borrador_` |
| cualquier otro | recibos | sí | visible | `Recibos_Borrador_` |

Se conservan verbatim los nombres de campo anteriores. Las columnas de
dirección, población, provincia, código postal e importe en letra solo
se muestran para recibos; la columna compartida de localidad/referencia
permanece visible en ambos orígenes.

Los dos plurales que antes eran literales del formulario pasan a
`inLibMsgFacturas` como `resourcestring`.

## 3. Medición

| Objetivo | Antes | Después | Variación |
|---|---:|---:|---:|
| `TfrmMtoFacturasBase` — líneas | 4.008 | **3.883** | −125 |
| `TfrmMtoFacturasBase` — métodos | 133 | **128** | −5 |

El trinquete propio baja a 3.883 líneas y 128 métodos. El objetivo final
del plan permanece en 2.000/120.

El comprobador global de tamaño sigue rojo por cambios ajenos a esta
tanda:

- `TfrmMtoOpeCaja`: 4.321, con tope 4.060;
- `TfrmStockConsulta`: 3.141, con tope 3.139.

`TfrmMtoFacturasBase` sí cumple su nuevo tope.

## 4. Pruebas

`tests\PruebasFacturasCobrosPresentacion.pas` aporta cuatro casos sin
BBDD:

1. factura normal: efectos, solo lectura y sin impresión;
2. factura simplificada: recibos editables y con impresión;
3. tipo no normal: conserva la rama de recibos;
4. los 19 campos están informados en ambos orígenes.

Resultado global en Release Win32 y Win64:

```text
Tests Found   : 411
Tests Passed  : 408
Tests Failed  : 3
Tests Errored : 0
Tests Leaked  : 0
```

Los cuatro casos nuevos no figuran entre los fallos. Los tres rojos
siguen siendo las expectativas conocidas del catálogo SQL:

- dos recuentos esperan 120 y obtienen 123;
- un recuento espera 7 y obtiene 10.

## 5. Trinquetes y compilación

Ejecutado el 31/07/2026:

- `fzam` Release Win32: compilado;
- `fzam` Release Win64: compilado;
- `FactuzamTests` Release Win32: compilado y ejecutado;
- `FactuzamTests` Release Win64: compilado y ejecutado;
- dependencias de capa: 500 unidades, ciclo mayor 1 y 0 usos
  `inLib*` → `UniData*`;
- SQL en dominio: 193 sentencias en 57 unidades, dentro del tope;
- SQL/transacciones/eventos críticos: correcto.

El descenso global de SQL respecto a la línea base procede de una tanda
concurrente y no se atribuye a esta extracción, que no contiene SQL.

## 6. Ficheros de la tanda

Nuevos:

- `src\Lib\inLibFacturasCobrosPresentacion.pas`;
- `tests\PruebasFacturasCobrosPresentacion.pas`;
- este informe.

Modificados:

- `src\Forms\inMtoFacturasBase.pas`;
- `src\Lib\inLibMsgFacturas.pas`;
- `fzam.dpr` y `fzam.dproj`;
- `tests\FactuzamTests.dpr` y `tests\FactuzamTests.dproj`;
- `scripts\comprobar_tamano_clases.ps1`;
- `PLAN_SOLID.md`.

Los ficheros de proyecto y de plan tenían cambios concurrentes. Las
entradas de esta tanda se añadieron sobre el contenido vigente sin
reemplazar esas modificaciones.

## 7. Prueba funcional pendiente

La verificación automática cubre las decisiones y los mapeos. Queda el
smoke visual:

1. abrir una factura normal y comprobar efectos en solo lectura;
2. abrir una simplificada y comprobar recibos editables;
3. verificar captions, impresión y exportación en ambos tipos;
4. generar cobros y comprobar que el diálogo usa el plural correcto.

El siguiente corte natural del fascículo es la coordinación fiscal o la
consolidación; ambos siguen dentro de `TfrmMtoFacturasBase`.
