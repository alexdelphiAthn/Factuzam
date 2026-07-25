# Informe de pruebas - Conexión global Fase XI-D

Fecha: 25/07/2026

## Resultado

XI-D queda aplicada y validada. La conexión global `oConn` ha
desaparecido definitivamente de `src` y `fzam.dpr`:

| Estado | Apariciones | Líneas | Unidades |
| --- | ---: | ---: | ---: |
| Tras XI-B1 | 169 | 165 | 36 |
| Tras XI-C | 62 | 62 | 8 |
| Tras XI-D | **0** | **0** | **0** |

`inLibGlobalVar` ya no declara ni inicializa la conexión y deja de
importar `Uni`. La raíz tampoco mantiene el puente
`oConn := FDmConn.conUni`.

## Sustituciones finales

Los tres módulos que no heredan de `TdmBase` reciben ahora la conexión
en su constructor:

```pascal
constructor Create(
  AOwner: TComponent;
  AConexion: TUniConnection);
```

Se aplica a:

- `TdmCajaOpe`;
- `TdmTraspaso`;
- `TdmConsultaOpe`.

La conexión se guarda antes de llamar al constructor heredado, porque
este dispara `DataModuleCreate`. Así, todas las queries quedan
configuradas desde el primer momento y las transacciones de caja y
traspaso siguen usando una única conexión para `StartTransaction`,
`Commit` y `Rollback`.

Los seis puntos de creación entregan `ConexionPrincipal` o la conexión
de trabajo `FConn`. También reciben conexión explícita:

- `RegistrarEventoFiscalSeguro`;
- `RegistrarCambioConfiguracionVerifactuSeguro`;
- `AnexoEmpresasInstalacionHtml`;
- `AgregarAnexoImpresion`;
- `FechaUltimoTicketSerie`.

Se retiran cuatro `uses inLibGlobalVar` que habían quedado huérfanos y
la prueba histórica X-D deja de tratar `oConn` como símbolo global
permitido. El libro de estilo se actualiza para exigir
`ConexionPrincipal` o `AConexion`.

## Prueba estructural

Script: `PruebasConexionGlobalFase11D.ps1`

Resultado: **15 comprobaciones, 15 correctas y 0 fallos**.

La barrera verifica:

1. cero referencias en `src` y `fzam.dpr`;
2. retirada de la declaración, inicialización e importación de UniDAC;
3. conservación de `TServicioConexionesUniDAC` como raíz de composición;
4. constructores explícitos de los tres módulos;
5. asignación de la conexión antes de `DataModuleCreate`;
6. conservación de las transacciones sobre la conexión inyectada;
7. actualización de todos los llamantes;
8. contratos fiscales explícitos;
9. continuidad de la barrera XI-C;
10. cero `uses inLibGlobalVar` huérfanos;
11. actualización de la prueba histórica X-D;
12. máximo de 80 columnas en líneas migradas;
13. conservación de conexiones persistentes DFM;
14. ausencia de cambios DFM propios de XI-D;
15. integridad de `factuzam_original.sql`.

## Compilación

Cadena usada: Delphi 37.0.

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

El detalle está en `resultado_compilacion.txt`. Permanecen avisos e
indicaciones ya existentes en el proyecto; las tres compilaciones
terminan con código de salida 0 y ninguna línea de error.

## Regresión automatizada

| Batería | Resultado |
| --- | ---: |
| Conexión global Fase XI-D | 15/15 |
| Conexión global Fase XI-C | 15/15 |
| Conexión global Fase XI-A | 11/11 |
| Conexión global Fase XI-B1 | 13/13 |
| Contexto de sesión Fase X-D | 11/11 |
| Contexto de sesión Fase X-C | 17/17 |
| Contexto de sesión Fase X-B | 13/13 |
| Contexto de sesión Fase X-A | 14/14 |
| Contexto de sesión Fase VIII | 18/18 |
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| **Total** | **164/164** |

## Compatibilidad

- Se conservan los **253** enlaces persistentes
  `Connection = dmConn.conUni` de **52 DFM**.
- XI-D no cambia ningún DFM.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` permanece intacto.
- No se ha realizado ningún commit ni push.

## Prueba funcional recomendada

1. Abrir caja, crear una venta, cobrarla y reimprimir el ticket.
2. Registrar gasto y entrada de cambio.
3. Crear, solicitar y atender un traspaso entre almacenes.
4. Abrir la consulta y el histórico de operaciones, cambiando entre
   pestañas de pagos, vales, movimientos y factura.
5. Guardar parámetros Verifactu y comprobar su evento fiscal.
6. Generar e imprimir la declaración responsable con su anexo de
   empresas e instalaciones.
