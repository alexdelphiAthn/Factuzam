# Trinquetes de arquitectura IA-S31

Este directorio contiene el analizador ejecutable de IA-S31 y sus fixtures.
No usa una baseline de excepciones: una infracción propia siempre hace fallar
la auditoría.

## Ejecución

Desde la raíz del repositorio:

```powershell
pwsh -NoProfile -File tests\arquitectura\PruebasArquitecturaS31.ps1
pwsh -NoProfile -File tests\arquitectura\comprobar_arquitectura_s31.ps1
```

El primer comando valida el propio trinquete. Incluye un fixture positivo, uno
en el límite y uno negativo para cada regla, además de los casos de
clasificación y de baseline no ampliable. El segundo audita el proyecto y
devuelve código `1` mientras exista deuda arquitectónica.

Para obtener todas las infracciones, sin el recorte de diagnóstico:

```powershell
pwsh -NoProfile -File `
  tests\arquitectura\comprobar_arquitectura_s31.ps1 -MostrarTodos
```

Los límites se pueden reducir de forma temporal:

```powershell
pwsh -NoProfile -File `
  tests\arquitectura\comprobar_arquitectura_s31.ps1 `
  -MaximoFanOutUi 44 -MaximoFanOutComposicion 46
```

Los parámetros rechazan cualquier valor superior a los topes versionados
(`45` para UI y `47` para composición). Por tanto, una ejecución no puede
ensanchar el trinquete.

## Reglas

| Código | Regla |
| --- | --- |
| `ARQ01_MAINFORM` | No resolver dependencias mediante `Application.MainForm`. |
| `ARQ02_DMCONN` | No acceder a `.DmConn` fuera de una raíz de composición UniDAC. |
| `ARQ03_DM_CREATE_UI` | La UI no crea directamente clases `Tdm*`. |
| `ARQ04_UNIDAC_CONTRATO` | Los contratos de dominio/UI no exponen tipos UniDAC. |
| `ARQ05_ESTADO_GLOBAL` | No almacenar registros o factorías en estado global mutable. |
| `ARQ06_FANOUT_UI` | El fan-out interno de una unidad UI no supera 45. |
| `ARQ06_FANOUT_RAIZ` | El fan-out interno de una raíz de composición no supera 47. |
| `ARQ07_CONTEXTO_NO_USADO` | Cada capacidad entregada por un contexto de pantalla se usa. |

El fan-out cuenta solo dependencias hacia otras unidades propias del proyecto;
no mezcla RTL, VCL ni componentes externos.

## Clasificación

El analizador informa por separado:

- código propio, que sí está sujeto a las reglas;
- código generado (`*.g.pas`, `*.designer.pas`, `*.generated.pas` o marcador
  equivalente);
- código de terceros ubicado en las raíces conocidas del repositorio.

Si existe `fzam.dpr`, solo se auditan las unidades enlazadas por el proyecto.
En las raíces aisladas de los fixtures se recorren todas las unidades de
`src`.

La activación completa depende de eliminar la deuda de IA-S10 a IA-S13. Hasta
entonces, que la auditoría real termine en rojo es intencionado: permite ver y
reducir la deuda sin convertirla en una excepción permanente.
