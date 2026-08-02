# Cómo contribuir a Factuzam

Las propuestas de mejora son bienvenidas mediante incidencias y solicitudes
de incorporación de cambios.

## Licencia de las contribuciones

Al enviar código, documentación o cualquier otro material para incorporarlo a
Factuzam, confirmas que:

- eres su autor o tienes autorización suficiente para aportarlo;
- aceptas que la contribución se distribuya bajo MPL-2.0;
- no contiene código propietario, secretos, credenciales ni datos de terceros;
- has identificado cualquier material externo y su licencia compatible.

El autor conserva sus derechos de autor. La contribución aceptada queda sujeta
a los permisos y obligaciones de MPL-2.0, incluido su posible uso comercial.

## Preparación de un cambio

1. Explica el problema y el resultado esperado.
2. Mantén el cambio limitado a una finalidad concreta.
3. Sigue `LIBRO_DE_ESTILO_DELPHI.md` y `LIBRO_DE_ESTILO_BBDD.md`.
4. Añade o actualiza pruebas cuando el comportamiento cambie.
5. Documenta las dependencias nuevas y justifica su incorporación.
6. Describe las comprobaciones realizadas.

Los cambios de esquema deben ser idempotentes y vivir en
`DESARROLLOS EN CURSO/`. No se debe modificar `factuzam_original.sql`.

## Código de terceros

No incluyas fuentes, paquetes, binarios o recursos de DevExpress, UniDAC,
FastReport, Delphi u otros productos comerciales. Para una dependencia libre,
conserva su licencia y atribución y actualiza `AVISOS_DE_TERCEROS.md`.

## Cabecera para archivos nuevos

Las unidades nuevas propias deben incluir el identificador:

```pascal
{ SPDX-License-Identifier: MPL-2.0 }
```

Cuando el formato no admita comentarios de forma segura, el aviso central de
`LICENCIAS.md` y `LICENSE` documenta el alcance.
