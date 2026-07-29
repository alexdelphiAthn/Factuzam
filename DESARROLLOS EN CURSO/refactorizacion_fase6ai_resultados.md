# Fase 6AI — NIF, CCC e IBAN

Fecha: 29/07/2026. D3.8, octavo fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 567 | 377 | **-190** |
| `inLibIBAN` | 528 | 271 | **-257** |
| `inLibIBAN.Types` | 415 | 0 | **-415** |
| `inLibDocumentoFiscal` | 236 | 233 | **-3** |
| Total productivo del alcance | 1.746 | 881 | **-865** |

El alcance productivo se reduce un **49,5 %**. Las 223 líneas de
`PruebasIdentificacionFiscalBancaria.pas` quedan excluidas.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 377 líneas, **-1.146 (-75,2 %)**;
- suma de los balances productivos declarados en D3.1-D3.8:
  **-621 líneas**;
- D3 queda en 8 de 9 fascículos.

## Implementación

La funcionalidad viva queda repartida en las dos unidades que ya
representaban estos dominios:

- `inLibDocumentoFiscal`: limpieza y validación de NIF, NIE y CIF,
  mensaje de error y reconocimiento de España;
- `inLibIBAN`: validación de IBAN y CCC, generación de IBAN,
  normalización electrónica, extracción y descomposición del CCC.

`inLibIBAN` publica únicamente las seis operaciones que tienen
consumidores de producción. Los registros auxiliares pasan a ser
innecesarios: el módulo calcula el módulo 97 y los dígitos del CCC con
helpers privados.

El cálculo de módulo 97 procesa tanto dígitos como letras según la
codificación IBAN. Esto mantiene los IBAN españoles y permite validar
correctamente los BBAN alfanuméricos de otros países.

## Código retirado

La búsqueda global confirmó que no tenían consumidores:

- las firmas de `inLibtb`: `LetraNIF`, `CalculaDC`, `DevDC`,
  `TomarLetra`, `SoloLetraNIF`, `SoloNumeros`, `SonNumeros`,
  `ComprobarNIF` y `CheckIBAN`;
- los métodos públicos de `TIBAN`: `GenerarDC`, `CalcularDCIBAN`,
  `FormatearPapel`, `ExtraerPais` y `ExtraerDCIBAN`;
- los tipos públicos `TrBancoCuentaInfo`, `TrBancoIBANInfo` y
  `TrBancoCCCInfoESP`;
- la unidad completa `inLibIBAN.Types`, que no estaba referenciada y
  dependía además de una unidad inexistente, `inLibIBAN.Funcs`;
- la exposición pública de `TTipoDocumentoFiscal` y
  `DocumentoFiscalValidoConTipo`, que sólo se usan dentro de
  `inLibDocumentoFiscal`.

No se mantiene fachada para firmas sin llamadas.

## Pruebas automáticas

`PruebasIdentificacionFiscalBancaria.pas` añade trece pruebas:

1. NIF válido con separadores y normalización;
2. NIE válido;
3. CIF válido;
4. NIF inválido y mensaje específico;
5. códigos y nombres que identifican España;
6. IBAN español válido;
7. IBAN británico con BBAN alfanumérico;
8. IBAN inválido con detalle de error;
9. CCC válido solo y dentro de un IBAN;
10. CCC con dígito de control incorrecto;
11. generación del IBAN español;
12. normalización y extracción del CCC;
13. descomposición del CCC.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 162/162 | 0 | 0 |
| Debug / Win32 | 0 errores | 162/162 | 0 | 0 |
| Release / Win64 | 0 errores | 162/162 | 0 | 0 |
| Release / Win32 | 0 errores | 162/162 | 0 | 0 |

La aplicación se reconstruyó con Delphi 37 en Release/Win64 dentro de
`build/validacion_d38/Win64/Release`: 0 errores, 311.361 líneas y
10,69 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.8 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- ninguna referencia a las firmas y tipos retirados;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check` limitado al alcance de D3.8.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Introducir un CCC válido e inválido en clientes y empresas.
2. Generar el IBAN español desde el CCC en ambas pantallas.
3. Guardar un IBAN de empresa y comprobar la descomposición en banco,
   dígito de control y cuenta.
4. Generar una remesa SEPA con IBAN español.
5. Validar facturas y tickets con NIF, NIE y CIF españoles.
6. Repetir la facturación con un cliente extranjero para comprobar que
   no se aplica la validación fiscal española.

D3 queda abierto: **8 de 9 fascículos**. El siguiente y último es
D3.9: cálculo de líneas de factura y cierre de la fachada `inLibtb`.
