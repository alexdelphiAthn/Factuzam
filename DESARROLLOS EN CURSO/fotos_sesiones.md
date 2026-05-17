# Fotos en sesiones de compras (pendiente)

## Problema

En `inMtoComprasSesiones`, las líneas trabajan con
`CODIGO_ART_TENTATIVO_SESLIN`: un código de artículo que **el usuario
teclea pero que todavía no existe** en `fza_articulos` hasta que se
materializa la sesión (`InLibComprasSesionesMaterializar`).

El subsistema de fotos actual exige una fila previa en `fza_articulos`
porque las claves de `fza_articulos_fotos` (`CODIGO_ART_FOT`) son FK
lógica. Si el usuario quiere subir la foto del artículo en el momento
de recepción de la mercancía (dentro de la sesión, antes de
materializar) no puede.

## Solución propuesta

Tabla **`fza_compras_sesiones_fotos`** análoga a `fza_articulos_fotos`
pero claveada por la línea de sesión:

```sql
CREATE TABLE `fza_compras_sesiones_fotos` (
  `SERIE_SES_CSF`            varchar(12)  NOT NULL,
  `NUMERO_SES_CSF`           varchar(12)  NOT NULL,
  `LINEA_CSF`                int(11)      NOT NULL,
  `CODIGO_UNIDAD_CSF`        varchar(50)  NOT NULL DEFAULT ''
      COMMENT 'SKU completo o prefijo dentro del articulo tentativo',
  `CODIGO_ART_TENTATIVO_CSF` varchar(20)  NOT NULL
      COMMENT 'Copia de CODIGO_ART_TENTATIVO_SESLIN; redundante para traza',
  `NOMBRE_FOT_CSF`           varchar(255) NOT NULL,
  `EXTENSION_ORIGEN_CSF`     varchar(10)  NOT NULL DEFAULT 'png',
  `INSTANTE_MODIF`           timestamp    NOT NULL
      DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `INSTANTE_ALTA`            timestamp    NOT NULL
      DEFAULT '0000-00-00 00:00:00',
  `USUARIO_ALTA`             varchar(100) NOT NULL,
  `USUARIO_MODIF`            varchar(100) NOT NULL,
  PRIMARY KEY (`SERIE_SES_CSF`, `NUMERO_SES_CSF`,
               `LINEA_CSF`, `CODIGO_UNIDAD_CSF`)
);
```

Ficheros bajo la misma `appDirFotos` con prefijo `ses_`:

```
<appDirFotos>/300/ses_<SERIE>_<NUMERO>_<LINEA>_<NNN>.png
<appDirFotos>/600/ses_<SERIE>_<NUMERO>_<LINEA>_<NNN>.png
<appDirFotos>/real/ses_<SERIE>_<NUMERO>_<LINEA>_<NNN>.png
```

## API a añadir en `inLibFotos`

```pascal
// Sube y registra una foto contra una linea de sesion (todavia sin
// articulo materializado). Misma logica de Guardar (300/600/real, PNG)
// pero contra fza_compras_sesiones_fotos.
function TFotosArticulos.GuardarSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodArtTentativo, ACodUnidad, AFicheroOrigen: string): TFotoInfo;

// Resuelve la foto por (sesion, linea), con fallback dentro de la
// propia linea (SKU completo -> prefijo -> sin SKU).
function TFotosArticulos.ResolverSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodUnidad: string = ''): TFotoInfo;
```

## Materialización

`InLibComprasSesionesMaterializar` recorre las líneas y crea los
artículos. **En ese mismo paso** debe llamar a una nueva rutina
`MigrarFotosSesion(ASerie, ANumero, ALinea, ACodigoArtMaterializado)`
que para cada fila de `fza_compras_sesiones_fotos`:

1. Renombra los tres PNG quitando el prefijo `ses_<SERIE>_<NUMERO>_<LINEA>_`
   y poniendo el `<CodigoArtMaterializado>_<NNN>`.
2. Inserta en `fza_articulos_fotos` con `CODIGO_ART_FOT =
   <CodigoArtMaterializado>` y `CODIGO_UNIDAD_FOT = <CODIGO_UNIDAD_CSF>`.
3. Borra la fila de `fza_compras_sesiones_fotos`.

Si materializar falla a mitad y se reintenta, la migración es
idempotente: si la fila destino ya existe en `fza_articulos_fotos` se
puede sobreescribir (mismo `(art, sku)`) o conservar la original según
la política que el resto del subsistema de materialización use.

## UI

Cuando `frmFotoArticulo` se abre con `Ctrl + Alt + F` desde
`inMtoComprasSesiones`, el override de `ResolverArtSkuActivo` ya
devuelve el `CODIGO_ART_TENTATIVO_SESLIN`. La pantalla debería:

- Detectar que el llamador es una sesión de compras (p.ej. via una
  property `EnSesion: Boolean` en el form, o mejor: que la propia
  pantalla pregunte a `oFotos.Resolver` y, si no encuentra, recurra a
  `oFotos.ResolverSesion(serie, numero, linea, sku)`).
- Al subir foto, guardar contra `fza_compras_sesiones_fotos` si el
  artículo aún no está en `fza_articulos`, contra `fza_articulos_fotos`
  si ya está.

Lo más limpio: una sub-clase ligera o un flag pasado al `VincularMtoPadre`.

## Estado actual

Hoy `inMtoComprasSesiones` solo tiene el override de
`ResolverArtSkuActivo` que devuelve el `CODIGO_ART_TENTATIVO_SESLIN`.
Si el artículo no existe en `fza_articulos`, el `oFotos.Resolver` no
encontrará nada y la subida fallará al hacer FK lookup contra
`fza_articulos`.

Esta tabla y la lógica de materialización quedan **pendientes** —
no entran en el primer release del subsistema de fotos.
