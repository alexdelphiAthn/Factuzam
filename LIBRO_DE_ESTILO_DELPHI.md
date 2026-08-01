# Libro de estilo de programación Delphi de Factuzam

Manual práctico para añadir unidades, formularios, data modules, modales y
librerías auxiliares respetando las convenciones del proyecto.

Documento hermano de `LIBRO_DE_ESTILO_BBDD.md`: ese cubre el esquema SQL;
este cubre el código Pascal / Delphi que lo consume.

---

## 1. Principios

1. **Todo en español** (identificadores, comentarios, mensajes, etiquetas),
   salvo las palabras reservadas de Pascal y los símbolos de bibliotecas de
   terceros (DevExpress `cx`/`dx`, JEDI `Jv`, UniDAC `un`).
2. **Ancho máximo 80 columnas.** Las cabeceras de unidad son cajas de 80
   exactos. El código de implementación puede llegar a 80 pero nunca pasar.
3. **Un fichero, una responsabilidad**: una unidad = un formulario, un data
   module, o un conjunto cohesivo de utilidades.
4. **Herencia obligatoria** para formularios: todo formulario hereda de
   `TfrmBase` (o de `TfrmMtoGen` si es mantenimiento). Nunca de `TForm`
   directamente.
5. **Los nombres de columna SQL viajan tal cual** dentro de persistencia y
   binding visual: `FieldByName('CODIGO_CLI_CLI')`, nunca traducidos ni
   camelizados. No atraviesan contratos de aplicación ni records de dominio.
6. **Sin notación húngara para tipos de control** (no `TfrmMtoClientes` para
   un panel): los prefijos de control (`btn`, `lbl`, `txt`...) indican el
   tipo VCL, no el tipo lógico. Para variables locales sí se usa prefijo
   corto de tipo (`s`, `i`, `b`, `o`).
7. **Todos los dfm se guardan como utf8 con BOM**, y también los pas y dpr.
8. **Acentos dentro de dfm y pas se ponen nativos áéñ y no como ansi (old legacy)**.
9. **Los finales de linea siempre son CRLF y no LF**, estamos programando en windows.
10. **No generar hints ni warnings**, mantener limpia la compilación.
11. **Las dependencias apuntan hacia abajo**: formularios y composición pueden
    conocer contratos, librerías y data modules; estos no conocen formularios.
12. **Sin estado global mutable nuevo**. Sesión, conexión, parámetros y
    servicios se reciben mediante interfaces, propiedades heredadas o
    parámetros explícitos.
13. **La UI coordina; no contiene el dominio**. Las reglas reutilizables,
    cálculos y transformaciones viven en unidades `inLib*` cohesivas.
14. **Todo código extraído debe quedar verificable**. La lógica pura se cubre
    con DUnitX y el SQL con las pruebas de integración correspondientes.
15. **SOLID y Clean Code son reglas de no regresión**. Cada cambio conserva o
    mejora la separación de responsabilidades, el sentido de las dependencias
    y los topes vigilados por `scripts/comprobar_calidad.ps1`.

---

## 2. Estructura de directorios

```
src/
├── Core/           Formularios troncales: Logon, Principal, Splash,
│                   AppParam, CajaParam, PreviewExcel, PreviewTicket,
│                   el base inMtoFrmBase y el catálogo de pantallas
├── Forms/          Formularios de mantenimiento (Mtos) y derivados
├── Modals/         Formularios modales reutilizables
├── DataModules/    Data modules UniDAC (UniData*)
├── Lib/            Unidades sin formulario: lógica, utilidades, helpers
├── Caja/           Subsistema de caja, con sus propias Forms, Modals,
│                   DataModules y Lib
├── Lib3par/        Wrappers de bibliotecas de terceros (recopilatorio)
├── vcl/ vcl37/     Forks/parches locales de VCL por versión
├── verifactu/      Subsistema Verifactu (AEAT)
├── 3rdpartyComp/   Componentes de terceros pinchados en el repo
└── utilnormbbdd/   Herramienta auxiliar (normalizador de BBDD)

tests/              Proyecto DUnitX y fixtures Pascal
scripts/            Comprobaciones estructurales y auxiliares de build
```

**Regla**: una unidad nueva entra en la carpeta que coincida con su prefijo
(ver §3). No mezclar mantenimientos con modales ni con librerías.

---

## 3. Nombres de fichero y de `unit`

Los ficheros `.pas`/`.dfm` y la directiva `unit` **coinciden carácter a
carácter** (incluida la mayúscula/minúscula del primer carácter).

### 3.1 Catálogo de prefijos de unidad

| Prefijo      | Categoría                              | Ejemplos                                                    |
|--------------|----------------------------------------|-------------------------------------------------------------|
| `inMtoFrm*`  | Formulario base                        | `inMtoFrmBase`                                              |
| `inMtoGen`   | Mantenimiento genérico (base de Mtos)  | `inMtoGen`                                                  |
| `inMto*`     | Mantenimiento concreto                 | `inMtoClientes`, `inMtoFacturas`, `inMtoArticulos`          |
| `inMtoModal*`| Modal (diálogo) de un Mto              | `inMtoModalCalcularMargen`, `inMtoModalAddBlockTarifa`      |
| `inLib*Intf` | Contrato sin implementación ni UI      | `inLibConexionesIntf`, `inLibParametrosIntf`                |
| `inLib*`     | Librería / servicio sin formulario     | `inLibFacturas`, `inLibIBAN`, `inLibGestorTareasMto`        |
| `UniData*`   | Data module UniDAC                     | `UniDataClientes`, `UniDataConn`, `UniDataGen`              |

### 3.2 Reglas para elegir el sufijo del nombre de unidad

- En **plural** si gestiona varios registros: `inMtoClientes`, no
  `inMtoCliente`.
- En **singular** si es operación puntual o modal sobre un único registro:
  `inMtoModalCalcularMargen`, `inMtoModalFacRec`.
- **Sin tildes ni eñes** en el nombre del fichero (sí en los comentarios).
  `inMtoModalAnio` y no `inMtoModalAño`.
- Mantén la palabra clave del dominio reconocible: si la tabla SQL es
  `fza_articulos_tarifas`, la unidad es `inMtoTarifas` o
  `inMtoArtTar` (ver §4 para el caso de clases con sufijo).

### 3.3 Categorías reservadas (Core)

Estas unidades viven en `src/Core/` y nunca llevan prefijo `inMto<dominio>`:

```
inMtoSplash        Pantalla de splash inicial
inMtoLogon         Autenticación + configuración de conexión
inMtoPrincipal     MDI principal con menú
inMtoFrmBase       Base de TODO formulario
inMtoAppParam      Parametrización global
inMtoCajaParam     Parametrización del TPV
inMtoPreviewExcel  Vista previa antes de exportar
inMtoPreviewTicket Vista previa de ticket
```

---

## 4. Nombres de clase

### 4.1 Catálogo

| Patrón de clase | Hereda de        | Para...                          |
|-----------------|------------------|----------------------------------|
| `TfrmBase`      | `TForm`          | Base visual y servicios heredados|
| `TfrmMtoGen`    | `TfrmBase`       | Base de todos los mantenimientos |
| `TfrmMto<X>`    | `TfrmMtoGen`     | Mantenimiento concreto           |
| `TfrmModal<X>`  | `TfrmBase`       | Modal/diálogo                    |
| `TfrmPrint<X>`  | `TfrmBase`       | Pantallas de impresión           |
| `TdmBase`       | `TDataModule`    | Base de data modules             |
| `Tdm<X>`        | `TdmBase`        | Data module concreto             |

### 4.2 Instancias de formularios y data modules

No se declaran variables globales nuevas `frmMtoXxx` ni `dmmXxx`. El
registro de pantallas y el propietario administran la vida del formulario;
el mantenimiento conserva su data module como campo privado tipado:

```pascal
type
  TfrmMtoClientes = class(TfrmMtoGen)
  private
    FDataModule: TdmClientes;
  public
    procedure CrearTablaPrincipal; override;
  end;
```

Las declaraciones globales que aún existan son legado del diseñador. No se
usan como localizador de servicios, de ventanas abiertas ni de data modules,
porque fallan con varias instancias de la misma pantalla.

### 4.3 Tipos auxiliares públicos

Records y enumerados públicos llevan prefijo del dominio para que no
colisionen en `uses`:

```pascal
TTipoIVA      = (tivaNormal, tivaReducido, tivaSuperReducido, tivaExento);
TTotalesIVA   = record ... end;
TTotalesFactura = record ... end;
TConfiguracionFactura = record ... end;
TCalcularMargenResult = record ... end;
```

Excepciones siempre `E<Nombre>`: `EInvalidUser`, `EPassWordCorrupt`.

### 4.4 Orden dentro de una clase

Dentro de cada sección de visibilidad (`private`, `protected`, `public` y
`published`) se declaran primero todos los campos y después los métodos y
propiedades. Delphi genera E2169 si aparece un campo detrás de un método:

```pascal
private
  FDataModule: TdmClientes;
  FInicializado: Boolean;
  procedure ConfigurarDataModule;
  function PuedeEditar: Boolean;
```

---

## 5. Prefijos de componente (en `.dfm` y como campos de la clase)

Todos los componentes visuales o no visuales **llevan prefijo de tipo en
minúscula**. Si el componente está ligado a un campo de la BBDD, el
**sufijo del campo va en MAYÚSCULAS** (ver §5.2).

Para controles nuevos se prefieren los equivalentes DevExpress (`TcxMemo`,
`TcxLabel`, `TcxButton`, etc.) salvo que el formulario heredado o una
limitación técnica exijan un control VCL distinto.

### 5.1 Tabla de prefijos canónicos

| Prefijo  | Tipo VCL                                    | Ejemplos                              |
|----------|---------------------------------------------|---------------------------------------|
| `btn`    | `TcxButton`, `TButton`                      | `btnGrabar`, `btnCancelar`, `btnIraFactura` |
| `lbl`    | `TcxLabel`, `TLabel`                        | `lblUsuario`, `lblTextoLegal`         |
**inicializar tcxLabel siempre con transparent = true**
| `txt`    | `TcxTextEdit`, `TcxDBTextEdit`              | `txtCODIGO_CLIENTE`, `txtRAZONSOCIAL_CLIENTE` |
| `edt`    | Editores no ligados a BBDD                  | `edtUser`, `edtPass`, `edtBusqGlobal` |
| `m`      | `TcxMemo`, `TcxDBMemo`                      | `mTEXTO_LEGAL_FACTURA_CLIENTE`        |
| `cbb`    | `TcxLookupComboBox`, `TcxComboBox`          | `cbbFORMAPAGO`, `cbbTARIFA`, `cbbPaises` |
| `chk`    | `TcxCheckBox`                               | `chkAuto`, `chkRememberUser`          |
| `rg`     | `TcxRadioGroup`                             | `rgTipoFactura`                       |
| `pnl`    | `TPanel`                                    | `pnlBody`, `pnlButtons`, `pnlFacturaCli` |
| `pc`     | `TcxPageControl`                            | `pcPantalla`, `pcPestanas`            |
| `ts`     | `TcxTabSheet`                               | `tsLista`, `tsFicha`, `tsDomicilioFiscal` |
| `tv`     | `TcxGridDBTableView`                        | `tvFacturacion`, `tvLineasFacturacion` |
| `cxgrd`  | `TcxGrid`                                   | `cxgrdPrincipal`, `cxgrdClientesFacturas` |
| `nv`     | `TcxDBNavigator`                            | `nvNavegador`                         |
| `sb`     | `TSpeedButton`                              | `sbExportExcel`                       |
| `ds`     | `TDataSource`                               | `dsTablaG`, `dsFacturasClientes`, `dsPaises` |
| `unqry`  | `TUniQuery`                                 | `unqryTablaG`, `unqryFacturasClientes` |
| `unstrdprc` | `TUniStoredProc`                         | `unstrdprcCrearPedido`                |
| `untbl`  | `TUniTable`                                 | `tbUsers` *(legacy: aceptable seguir el patrón en Logon)* |
| `cds`    | `TClientDataSet`                            | `cdsEtiquetas`                        |
| `dtstprv`| `TDataSetProvider`                          | `dtstprvEtiquetas`                    |
| `fxds`   | `TfrxDBDataset`                             | `fxdsEtiquetas`                       |
| `act`    | `TAction`                                   | `actEmpresas`, `actFacturas`          |

Ojo! NUNCA usar una palabra reservada del lenguaje para nombrar una variable. 


### 5.2 Componentes ligados a un campo de BBDD

Cuando el componente edita o muestra una columna concreta, el nombre =
`<prefijo><NOMBRE_COLUMNA_TAL_CUAL>`:

```pascal
txtCODIGO_CLIENTE      // edita la columna lógica "código del cliente"
txtNIF_CLIENTE
txtRAZONSOCIAL_CLIENTE
mTEXTO_LEGAL_FACTURA_CLIENTE
txtINSTANTEALTA
```

Aunque la columna real en BBDD lleve sufijo (`CODIGO_CLI_CLI`), en el
nombre del control **se usa la forma desplegada** del concepto. El binding
real al campo se hace por `DataField` en el `.dfm`.

### 5.3 Componentes auto-numerados — NO se aceptan

DevExpress crea por defecto nombres como `cxGridDBColumn37`, `pnl1`,
`cxgrdbclmn1`. **Estos hay que renombrarlos antes de hacer commit**, salvo
los que vivan en formularios heredados como tabla "muerta" pendiente de
limpieza. El patrón cuando son columnas de grid es:

```
<nombreDelGrid o DelTV><NOMBRE_COLUMNA>

ej: tvFacturacionTOTAL_LIQUIDO_FACTURA
    tvDepositosClienteCODIGO_ARTICULO_DEP
```

### 5.4 Componentes "principales" del formulario (heredados)

Estos vienen de `TfrmMtoGen` y **nunca se renombran**:

```
pcPantalla          TcxPageControl con las pestañas del Mto
tsLista, tsFicha    pestañas estándar
cxgrdPrincipal      grid de la lista
cxGrdDBTabPrin      TableView principal
dsTablaG            DataSource principal
btnGrabar, btnCancelar
nvNavegador
edtBusqGlobal
```

En el data module concreto, el dataset principal es siempre
`unqryTablaG: TUniQuery` (lo espera el form base).

---

## 6. Cabecera de unidad

Toda unidad nueva empieza con la siguiente caja de 80 columnas exactas:

```pascal
{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifas                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    <una o varias líneas describiendo el propósito de la unidad>              }
{******************************************************************************}
```

Valores aceptados en `Tipo`:

- `Formulario (Core)` — para unidades de `src/Core/`
- `Formulario (Mto)`  — mantenimientos en `src/Forms/`
- `Formulario (Modal)` — modales en `src/Modals/`
- `Formulario (Print)` — pantallas de impresión
- `Data Module`       — data modules UniDAC
- `Librería`          — unidades sin formulario

La cabecera está antes de `unit`. Las unidades antiguas tienen la cabecera
corta de 7 líneas (`FactuZam / Copyright (C) 2023 ...`); al tocarlas, **se
sustituye por la caja larga**.

---

## 7. Cláusula `uses`

### 7.1 Orden y agrupación

```pascal
uses
  // 1. RTL y VCL (Winapi, System, Vcl, Data)
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  // 2. Bibliotecas de terceros (cx, dx, Jv, Uni, frx)
  cxClasses, cxLocalization, dxSkinsCore, ...,
  JvComponentBase, JvEnterTab,
  Uni, MemDS, DBAccess,

  // 3. Contratos y unidades del proyecto (base → contratos → libs → datos)
  inMtoFrmBase,
  inLibContextoSesionIntf, inLibConexionesIntf,
  inLibUser,
  UniDataConn;
```

En la práctica los `.pas` generados por el IDE no respetan la separación
con comentarios; **no merece la pena reordenarlos a mano** salvo que estés
limpiando un fichero. Sí merece la pena:

- Pasar las dependencias del proyecto al final del `uses` de `interface`.
- Mover a `uses` de `implementation` cualquier dependencia que solo se
  usa en `procedure`/`function`, especialmente para romper referencias
  circulares entre Mtos.
- Eliminar todo `uses` muerto al tocar una unidad.
- No esconder una dependencia de capa moviéndola a `implementation`:
  `inLib*` y `UniData*` tampoco pueden usar `inMto*` desde esa sección.
- Depender del contrato `inLib*Intf`, no de la implementación concreta,
  cuando el consumidor solo necesita el servicio.

### 7.2 Anti-patrón: dejar las skins inflando el `uses`

DevExpress añade ~50 unidades `dxSkin*` cada vez que se abre un form en el
IDE. Es ruido inevitable; no se borra porque rompe la previsualización,
pero **no añade líneas más** por encima de las que ya hay.

---

## 8. Indentación, espacios y ancho

### 8.1 Reglas duras

- **2 espacios** por nivel de indentación. Nunca tabuladores.
- **80 columnas máximo** por línea. Si te pasas, parte (ver §8.2).
- Una sentencia por línea. La condición de `if`, `while` o `for` ocupa
  una línea y la acción, como mínimo, la siguiente.
- `begin` en línea propia, alineado con la palabra clave que lo abre.
- Evitar `Exit` y `Continue`. Estructurar el método con condiciones
  positivas y bloques acotados.

```pascal
// Sí
if Assigned(oConsulta) then
  oConsulta.Open;

// No
if Assigned(oConsulta) then oConsulta.Open;
```

### 8.2 Cómo partir líneas largas

Partir antes del operador o tras la coma, y **alinear bajo el primer
argumento** (a 2 niveles del inicio si la firma es muy profunda):

```pascal
// Sí
ShowMto(Self.Owner,
        'Empresas',
        tvFacturacion.DataController.DataSet.FieldByName(
                                            'CODIGO_EMP_FAC').AsString);

// Sí (asignaciones largas)
sNroFactura := tvFacturacion.DataController.DataSet.FieldByName(
                                                      'NUMERO_FAC').AsString;
```

### 8.3 Alineación opcional de bloques

Cuando un bloque de asignaciones repite el mismo destino o tiene
estructura uniforme, se permite alinear los `:=`:

```pascal
unqryTablaG.Connection           := ConexionPrincipal;
unqryPedidosLineas.Connection    := ConexionPrincipal;
unqryLinPedido.Connection        := ConexionPrincipal;
unqryEmpDataPedido.Connection    := ConexionPrincipal;
```

Igual con las firmas de funciones de muchos parámetros:

```pascal
class function Ejecutar(
  AOwner                    : TComponent;
  AConn                     : TUniConnection;
  ACodigoUnicoArttar        : Integer;
  const ACodigoArt          : string;
  const ACodigoUnidadArttar : string;
  ...
): TCalcularMargenResult;
```

### 8.4 Espacios

- **Sí** espacio tras comas: `Foo(a, b, c)`.
- **No** espacio justo dentro de paréntesis: `Foo(a)` no `Foo( a )`.
- **Sí** espacios alrededor de operadores binarios: `a + b`, `x := y`.
- **No** doble espacio dentro del código (sí permitido para alinear según §8.3).

---

## 9. Naming de identificadores Pascal

### 9.1 Convenciones generales

| Cosa                       | Estilo            | Ejemplo                       |
|----------------------------|-------------------|-------------------------------|
| Tipo (`T...`)              | `TPascalCase`     | `TTotalesFactura`             |
| Excepción (`E...`)         | `EPascalCase`     | `EInvalidUser`                |
| Interfaz (`I...`)          | `IPascalCase`     | `IValidador`                  |
| Constante                  | `CamelCase` o `UPPER_CASE` (constantes "tipo C") | `MaxItems`, `IVA_GENERAL` |
| Función / procedimiento    | `PascalCase`      | `CalcularPrecioSalida`        |
| Método público             | `PascalCase`      | `Ejecutar`, `ResetForm`       |
| Método privado             | `PascalCase`      | `PersistirCambios`            |
| Parámetro                  | `APascalCase`     | `AOwner`, `ACodigoCli`        |
| Campo privado de clase     | `FPascalCase`     | `FConn`, `FResultado`         |
| Propiedad                  | `PascalCase`      | `Conexion`, `CodigoCliente`   |
| Variable local             | `<prefijo>Nombre` | ver §9.2                      |

### 9.2 Prefijos de variables locales (corto, "tipo C")

| Prefijo | Tipo                  | Ejemplos                          |
|---------|-----------------------|-----------------------------------|
| `s`     | `string`              | `sNroFactura`, `sCodCli`, `sErr`  |
| `i`     | `Integer`             | `iLen`, `iNroEspaciosBlanco`      |
| `b` / `Es` | `Boolean`          | `bEncontrado`, `EsIBANErr`        |
| `d`     | `Double` / `Currency` | `dImporte`, `dTotal`              |
| `dt`    | `TDateTime`           | `dtAlta`, `dtVencimiento`         |
| `o`     | objeto                | `oCliente`, `oServicio`           |
| `st`    | `TStringList`         | `stErr`, `stLineas`               |
| `f`     | constante de nombre de campo (ver §11) | `fnrofac`, `fcodcli` |

Es **opcional** pero ampliamente usado. Coherencia dentro de la unidad
prevalece sobre purismo: si todo el fichero usa `sIBAN`, no metas
`ibanText`.

### 9.3 Booleanos en Pascal

Variables y campos booleanos llevan prefijo `Es` (sin guion, como en la
BBDD):

```pascal
EsIBANErr := False;
EsFacturaSimplificada: Boolean;
EsRegimenAgricolaEmpresa: Boolean;
EsIntracomunitario: Boolean;
```

Para variables locales muy efímeras se acepta `b`: `bOk`, `bSeguir`.

### 9.4 Métodos: imperativo en español

Los métodos llevan verbo en infinitivo en español:

```
Validar           Calcular          Persistir         Recalcular
Generar           Mostrar           Cargar            Grabar
Cancelar          Crear             Buscar            Ejecutar
```

Excepciones: callbacks generados por el IDE (`btnXxxClick`,
`FormCreate`, `dsTablaGStateChange`).

---

## 10. Patrones de formulario

### 10.1 Formulario de mantenimiento (`TfrmMto<X>`)

El formulario conserva la presentación y la coordinación de la pantalla.
No duplica reglas de dominio ni accede a servicios globales. Sobreescribe
solo los hooks que necesita:

```pascal
type
  TfrmMtoClientes = class(TfrmMtoGen)
    // componentes...
  private
    FDataModule: TdmClientes;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;
```

`CrearTablaPrincipal` tipa el data module creado por la base y conecta los
controles propios. `TfrmMtoGen` ya le ha transmitido conexión, servicios y
el `dsTablaG` mediante `TdmBase.AsignarMaestroCabecera`:

```pascal
procedure TfrmMtoClientes.CrearTablaPrincipal;
begin
  inherited;
  FDataModule := tdmDataModule as TdmClientes;
  tvFacturacion.DataController.DataSource :=
    FDataModule.dsFacturasClientes;
  Self.pkFieldName := 'CODIGO_CLI_CLI';
end;
```

Un formulario no añade a `TfrmMtoGen` una responsabilidad que solo usa una
pantalla. Si la lógica se repite, se extrae a un colaborador cohesivo y el
formulario conserva únicamente el cableado.

### 10.2 Formulario modal (`TfrmModal<X>`)

Patrón: **punto de entrada de clase `Ejecutar`** que crea, configura, muestra
y libera el formulario, devolviendo un record con el resultado:

```pascal
type
  TCalcularMargenResult = record
    Aceptado          : Boolean;
    PrecioCoste       : Double;
    PrecioSalidaFinal : Double;
  end;

  TfrmModalCalcularMargen = class(TfrmBase)
    ...
  public
    class function Ejecutar(
      AOwner               : TComponent;
      AConn                : TUniConnection;
      ACodigoUnicoArttar   : Integer;
      const ACodigoArt     : string;
      ...
    ): TCalcularMargenResult;
  end;
```

Uso en el llamador:

```pascal
res := TfrmModalCalcularMargen.Ejecutar(
  Self,
  ConexionPrincipal,
  idArttar,
  ...);
if res.Aceptado then
  ...
```

Esta variante evita exponer `frmModalXxx.ShowModal` en cada llamador.

El modal recibe por parámetros o por un record de configuración todo lo que
necesita. Nunca conoce ni hace cast al mantenimiento que lo abrió. Devuelve
un resultado; no escribe directamente en campos privados del llamador.

### 10.3 Data module (`Tdm<X>`)

- Hereda de `TdmBase`.
- Su query principal se llama **siempre** `unqryTablaG`.
- Usa `ConexionPrincipal`, `ContextoSesion`, `ParametrosApp`,
  `ParametrosCaja` y los demás servicios heredados de `TdmBase`.
- Recibe el maestro desde el formulario mediante
  `AsignarMaestroCabecera`; nunca sube al propietario con
  `GetOwnerForm<TfrmXxx>`.
- No manipula controles, pestañas, foco ni handlers del formulario. Para
  solicitar una reacción visual expone un evento, callback o resultado de
  dominio y el formulario decide cómo representarlo.
- Métodos de servicio en `PascalCase`: `GetCodigoAutoCliente`,
  `CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer; sCodCli: string)`.

```pascal
procedure TdmClientes.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryFacturasClientes.MasterSource := ADataSource;
  unqryDepositos.MasterSource := ADataSource;
end;
```

### 10.4 Registro de pantallas y data modules

Cada clase que abre `ShowMto` se registra por referencia compilada en la
propia unidad que declara la clase:

```pascal
uses
  inLibRegistroPantallas,
  ...;

initialization
  RegistrarPantalla(TfrmMtoClientes);

end.
```

El data module aplica el mismo patrón en `UniDataClientes.pas`:

```pascal
initialization
  RegistrarDataModule(TdmClientes);

end.
```

La clave se obtiene de `QualifiedClassName`. No se resuelve una clase con
RTTI a partir de una cadena de BBDD ni se usa `NewInstance` manualmente.
Al añadir una pantalla:

1. Añadir las unidades al `.dpr` y al `.dproj`.
2. Auto-registrar cada clase en el `initialization` de su propia unidad.
3. Añadir o revisar la fila de `fza_winforms`.
4. Conectar el ítem de menú a `MenuGenericoClick` si solo abre la pantalla.
5. Comprobar al arrancar que `TfzaWinF.ComprobarRegistradas` no informa de
   clases ausentes.
6. Ejecutar `scripts/comprobar_registro_pantallas.ps1`.

`ForceReferenceToClass` es legado y no sustituye el registro. No se añade
a unidades nuevas.

---

## 11. Constantes para nombres de columna SQL

En cada adaptador `UniData*` que manipula una tabla, **declarar constantes
con el prefijo `f`** (de *field*) para evitar literales repetidos por toda la
unidad. Patrón: nombre corto en minúsculas, valor = nombre real de la
columna.

```pascal
const
  fnrofaclin   = 'NUMERO_FAC_FACLIN';
  fserielin    = 'SERIE_FAC_FACLIN';
  fnrolin      = 'LINEA_FACLIN';
  fcodart      = 'CODIGO_ART_FACLIN';
  fdesart      = 'DESCRIPCION_ARTICULO_FACLIN';
  fcant        = 'CANTIDAD_FACLIN';
  fporiva      = 'PORCENTAJE_IVA_FACLIN';
  ftotciva     = 'TOTAL_FACLIN';
```

Uso:

```pascal
Linea.FieldByName(fcant).AsCurrency := 1.0;
Linea.FieldByName(fporiva).AsCurrency := IVAGeneral;
```

**No** se usan en formularios ni en contratos `inLib*Intf`. Los `.dfm`
referencian el nombre real por `DataField`; los records de dominio usan
nombres del negocio. El SQL y sus constantes físicas pertenecen a
`UniData*`.

---

## 12. Manejo de errores y recursos

### 12.1 `try / finally` con `FreeAndNil`

Para objetos creados localmente, el patrón canónico es:

```pascal
formulario := TfrmPrintCliEti.Create(Application);
try
  formulario.edtCodCli.Text :=
                      dsTablaG.Dataset.FieldByName('CODIGO_CLI_CLI').AsString;
  formulario.ShowModal;
finally
  FreeAndNil(formulario);
end;
```

**Siempre `FreeAndNil`**, no `Free` a secas. Razón histórica: protege de
doble liberación si una excepción posterior vuelve a tocar la variable.

La variable se inicializa antes de entrar en ramas que puedan saltarse su
creación. Las interfaces gestionadas por contador de referencias se liberan
asignando `nil`; no se les aplica `FreeAndNil`.

### 12.2 `try / except` solo cuando hay reacción posible

No envolver bloques en `try / except` solo para silenciar errores. Si no
sabes qué hacer con la excepción, déjala subir al manejador global.

### 12.3 Excepciones de dominio

Crear `EXxx = class(Exception)` cuando hace falta distinguir en el
`except`. Ejemplo real (`inMtoLogon`):

```pascal
type
  EInvalidUser     = class(Exception);
  EPassWordCorrupt = class(Exception);
```

---

## 13. Comentarios

### 13.1 Cuándo SÍ

- Cabecera de unidad (§6) — obligatoria.
- Cabecera de sección dentro de la implementación, con regla horizontal:
  ```pascal
  // ===========================================================================
  //   API pública
  // ===========================================================================
  ```
- Aclarar **por qué** se hace algo no obvio (atajo de teclado, workaround
  de DevExpress, particularidad fiscal).
- Marca de atajo cuando el método responde a Ctrl+X:
  ```pascal
  procedure TfrmMtoClientes.actEmpresasExecute(Sender: TObject);
  begin
    //control + E -> Empresas
    inherited;
    ...
  ```

### 13.2 Cuándo NO

- Para explicar qué hace una línea evidente.
- Para dejar código comentado *por si acaso*. Bórralo; git lo conserva.

---

## 14. Arquitectura para hacer crecer el código

Esta sección convierte en reglas permanentes las decisiones de la
refactorización. El objetivo no es solo reducir líneas, sino evitar que
vuelvan los ciclos, el estado global y las clases con responsabilidades
incompatibles.

### 14.1 Dirección de dependencias

Las dependencias válidas siguen esta dirección:

```text
fzam.dpr / Core (composición)
            |
            v
Forms / Modals (presentación y coordinación)
            |
            v
UniData* (persistencia) ---> inLib* (dominio y colaboradores)
                                  |
                                  v
                            inLib*Intf (contratos)
```

Reglas:

- `inLib*` y `UniData*` no usan ninguna unidad `inMto*`, ni en
  `interface` ni en `implementation`.
- **`inLib*` no usa ninguna unidad `UniData*`.** La flecha del diagrama
  va en un solo sentido: la persistencia depende del dominio, nunca al
  revés. Una librería que necesita datos recibe un contrato
  `inLib*Intf` por constructor o por parámetro; no instancia un
  repositorio ni sabe que existe UniDAC.
- Quien construye los repositorios es la raíz de composición: `fzam.dpr`,
  `TfrmMtoPrincipal`, `TfrmBase` y `TdmBase`. Una unidad `inLib*` puede
  ser **factoría** —ensamblar piezas de dominio— pero recibe los
  adaptadores de persistencia ya construidos. Si una factoría necesita
  `uses UniData*`, está haciendo de raíz de composición y no le
  corresponde.
- Una fachada `inLib*` que solo re-exporta tipos de una unidad
  `UniData*` no es una capa: es un préstamo de nombre. Los tipos viven
  en `inLib*Intf` y los consumidores los toman de ahí.
- Una unidad `inLib*Intf` declara contratos pequeños y tipos estables. No
  usa formularios, data modules ni implementaciones concretas.
- Los formularios pueden conocer data modules y librerías. La capa inferior
  nunca hace cast al formulario ni llama a uno de sus handlers.
- `inMtoPrincipal` es raíz visual, no una librería transversal. Ninguna
  utilidad depende de él.
- Mover un `uses` a `implementation` puede romper un ciclo técnico, pero no
  corrige una dependencia de capa inválida.

La barrera automática se ejecuta desde la raíz:

```powershell
.\scripts\comprobar_dependencias_capas.ps1
```

El script vigila **las dos direcciones**: `inLib*`/`UniData*` → `inMto*`
y `inLib*` → `UniData*`. Ambos topes están en 0 y solo pueden bajar.

No se añaden excepciones ni listas blancas.

### 14.2 Composición e interfaces

`fzam.dpr` y `TfrmMtoPrincipal` forman la raíz de composición: crean las
implementaciones y publican sus contratos. El resto del proyecto consume
interfaces, no busca singletons ni instancia implementaciones por su cuenta.

- Formularios y data modules descendientes usan los servicios heredados de
  `TfrmBase` y `TdmBase`: conexiones, contexto, identidad, auditoría,
  permisos, parámetros, perfiles, filtros y monitor SQL.
- Un propietario publica un servicio mediante `IProveedorXxx`; las bases lo
  heredan con `Supports`. Esto propaga dependencias por el árbol de
  propietarios sin convertirlo en un localizador global.
- `Supports` solo se usa durante la creación, la composición o los métodos
  `Heredar*` incluidos en su lista blanca. El contrato resuelto se guarda en
  un campo y no vuelve a descubrirse desde métodos de negocio.
- Librerías, hilos y objetos sin propietario reciben los contratos en el
  constructor o en el método que inicia el trabajo.
- Los parámetros de interfaz se pasan como `const` cuando no se reasignan.
- La interfaz y su implementación viven en unidades distintas cuando eso
  evita que el consumidor arrastre UniDAC, VCL o DevExpress.
- Las interfaces propias llevan GUID y exponen la operación mínima que el
  consumidor necesita.
- Si una implementación ofrece varias capacidades, se publican interfaces
  pequeñas y un `record TServiciosXxx` para inyectarlas juntas. El consumidor
  solo conserva las capacidades que usa.

No se depende de `inLibAppParam`, `inLibCajaParam` ni de otra implementación
concreta cuando basta `IParametrosAplicacion`, `IParametrosCaja` o el
contrato correspondiente.

### 14.3 Estado compartido

`inLibGlobalVar` contiene solo constantes generales inmutables. No se añade
estado mutable a esa unidad ni a ninguna otra sección `interface`.

Queda prohibido introducir:

- conexiones, credenciales o identidad de sesión globales;
- referencias globales a formularios, data modules o controles VCL;
- callbacks globales y flags globales de ciclo de vida;
- cachés globales cuyo propietario y liberación no estén definidos.

Las constantes de dominio viven en la librería de su dominio. Una caché o un
servicio compartido pertenece a un objeto con propietario y ciclo de vida
explícitos.

### 14.4 Frontera entre UI, datos y dominio

- El formulario muestra, pide confirmación, decide pestaña y mueve el foco.
- El data module consulta y persiste datos, y aplica eventos de dataset.
- La librería contiene cálculos, validaciones y transformaciones
  reutilizables.

Si una capa inferior necesita provocar una reacción visual, expone un
evento, callback o record de resultado. Si necesita abrir una UI desde una
API heredada, declara un contrato o ejecutor en `inLib*` y la unidad
`inMto*` registra la implementación visual.

```pascal
type
  TResultadoValidacion = record
    EsValido: Boolean;
    Campo: TCampoValidacion;
    Mensaje: string;
  end;
```

El resultado describe el dominio; no contiene `TControl`, `TForm` ni una
referencia al llamador.

La identidad de una pantalla abierta usa una clave estable del registro
(`CALL#instancia`), nunca `Caption`, `ClassName` ni texto traducible.

### 14.5 Colaboradores y tamaño

Las clases base no son el destino automático de todo comportamiento común.
Antes de ampliar `TfrmMtoGen`, `TfrmMtoPrincipal` o una familia de
documentos se decide si la responsabilidad pertenece a:

- un colaborador `TGestorXxx` con ciclo de vida explícito;
- una función pura de dominio;
- una estrategia detrás de una interfaz;
- un record de configuración más una operación común;
- un data module o servicio de persistencia.

Un método nuevo debe representar un paso con nombre. Los límites P5 son:

- handler VCL: hasta 15 líneas efectivas de cuerpo;
- método normal: hasta 60 líneas efectivas y, preferiblemente, menos de 40;
- método fiscal, de caja o transaccional: hasta 10 decisiones;
- anidación: hasta dos niveles; el tercero exige extraer condición o paso;
- ningún método nuevo supera 80 líneas sin una excepción arquitectónica
  documentada y aprobada.

Los umbrales de 120 y 200 líneas que vigilan los scripts son límites de
migración del legado, no tamaños aceptables para código nuevo. Al tocar un
método de más de 120 líneas se reduce alguna de sus medidas siempre que el
alcance lo permita. No se crea ni amplía ninguno de más de 200 líneas.

Los objetivos de migración para las clases-dios vigiladas son 2.000 líneas y
120 métodos por clase. Para las unidades procedurales vigiladas son 1.200
líneas y 30 rutinas. Son techos para reducir legado, no tamaños aceptables
para una clase o unidad nueva. Cada pieza nueva recibe en
`comprobar_tamano_clases.ps1` el límite menor que corresponda a su función.

Los topes individuales solo pueden bajar. Una extracción se considera
completa cuando reduce al menos una medida de la pieza original sin trasladar
el monolito entero a la pieza nueva.

La extracción se hace por fascículos pequeños: fijar comportamiento con
pruebas, extraer una responsabilidad, compilar y solo entonces continuar.

### 14.6 Duplicación y fachadas de migración

Se unifica comportamiento equivalente, no código que solo se parece.

- Si dos flujos difieren en tabla, campos o opciones, usar un record de
  configuración o una estrategia.
- Si difieren en modelo, ciclo de vida o reglas, compartir únicamente el
  núcleo que sea realmente común.
- Una unidad muy usada puede conservar temporalmente una fachada compatible
  durante la migración de consumidores.
- La fachada no recibe lógica nueva. Se elimina cuando el último consumidor
  usa la unidad de dominio correcta.
- No se crean nuevas unidades cajón de sastre como la antigua `inLibtb`.

### 14.7 SQL, transacciones y eventos de dataset

- Todo valor externo se envía mediante parámetros UniDAC. Solo se concatenan
  fragmentos estructurales controlados por código, nunca texto de usuario.
- Una operación que escribe en varias tablas es atómica. Si recibe una
  conexión con transacción activa, la respeta; si abre la suya, hace
  `Commit` o `Rollback` en el mismo nivel.
- Los eventos `AfterPost`, `BeforePost` y similares no coordinan por sí
  solos procesos de negocio con varias escrituras. Delegan en una operación
  explícita que pueda probarse y controlar su transacción.
- No se silencian excepciones. Se registra contexto cuando aporta valor y se
  propaga el error, o se devuelve un resultado/aviso que el llamador debe
  atender.
- Los reintentos y materializaciones deben ser idempotentes cuando el flujo
  pueda repetirse tras un fallo.

### 14.8 Tareas en segundo plano

- Un hilo no accede a controles VCL ni a datasets que usa la UI.
- Cada tarea obtiene su conexión de trabajo mediante
  `IServicioConexiones`; no comparte la conexión principal.
- Los datos cruzan la frontera del hilo como valores, records o copias
  independientes, no como componentes con propietario visual.
- La actualización visual vuelve al hilo principal mediante el callback
  previsto por el gestor de tareas.
- Al cerrar o hacer re-login se cancelan y esperan las tareas antes de
  invalidar servicios y liberar propietarios.

### 14.9 Pruebas y ritmo de refactorización

`tests/FactuzamTests.dproj` es la red DUnitX del código Pascal:

- Toda función pura, regla extraída o colaborador sin UI añade casos DUnitX.
- Antes de sustituir lógica duplicada, las pruebas fijan el comportamiento
  de ambas rutas, incluidos límites y errores conocidos que deban
  conservarse.
- Los fixtures crean sus datos y liberan sus recursos; no dependen de una
  BBDD real salvo que la prueba se marque expresamente como integración.
- Las baterías Python siguen cubriendo SQL, procedimientos y contratos de
  datos. Complementan DUnitX; no lo sustituyen.
- Un refactor no mezcla cambios funcionales ni normalizaciones masivas de
  formato.
- Todo bug corregido añade una prueba de regresión que falle antes del
  cambio y pase después.
- Un caso de uso cubre, según corresponda, éxito, entrada límite, rechazo
  esperado, excepción, cancelación y rollback.
- Un adaptador que traduce campos o tipos añade pruebas de contrato para
  campos obligatorios, opcionales y conversiones.
- El número de pruebas no sustituye la cobertura. En dominio y aplicación
  se mide cobertura cuando exista soporte en el runner; fiscalidad, caja y
  transacciones tienen prioridad sobre la cobertura de componentes VCL.

Ejecución básica:

```bat
msbuild tests\FactuzamTests.dproj /t:Build /p:Config=Debug /p:Platform=Win64
tests\bin\Win64\Debug\FactuzamTests.exe
```

Antes de cerrar una refactorización transversal se valida también Release y
las plataformas Win32/Win64 afectadas.

### 14.10 SOLID aplicado a Factuzam

SOLID no se usa como una cuota de clases o interfaces. Se usa para que el
código pueda cambiar por una causa concreta sin arrastrar la UI, la BBDD ni
otros dominios. En Factuzam cada principio se traduce así:

| Principio | Regla comprobable en el proyecto |
|-----------|-----------------------------------|
| **S — Responsabilidad única** | Una unidad, clase o método tiene un motivo principal de cambio. |
| **O — Abierto/cerrado** | Una variante nueva entra por configuración, estrategia o registro, no copiando un flujo. |
| **L — Sustitución de Liskov** | Un descendiente mantiene el contrato observable de su ancestro. |
| **I — Segregación de interfaces** | Cada consumidor recibe solo las operaciones que necesita. |
| **D — Inversión de dependencias** | El dominio depende de contratos; la raíz conecta UniDAC y la UI. |

Referencias ya aplicadas en el código:

- `inLibGestorFiltrosMto` para un colaborador extraído de un formulario;
- `inLibComprasSesionesIntf`, `inLibComprasSesiones` y
  `UniDataComprasSesionesRepositorio` para contrato, dominio y adaptador;
- `inLibDocumentoIntf` e `inMtoDocumento` para configuración y estrategia.

Si aplicar un patrón añade más acoplamiento o hace más difícil leer un caso
sencillo, no se fuerza. Primero se identifica el cambio real que hay que
aislar y después se elige la pieza mínima que lo consigue.

### 14.11 Responsabilidad única (SRP)

Una responsabilidad no equivale a «hacer una sola instrucción». Equivale a
tener un único actor o causa principal que obligue a modificar la pieza.

- Un formulario cambia por presentación y coordinación de la interacción.
- Un data module cambia por persistencia, consultas y eventos de dataset.
- Una librería de dominio cambia por una regla, cálculo o transformación.
- Un adaptador `UniData*` cambia por el esquema o por detalles de UniDAC.
- Una unidad `inLib*Intf` cambia cuando cambia el contrato del consumidor.

Un handler visual sigue, por norma, este flujo: recoge la entrada visual,
invoca la operación correspondiente y representa el resultado. Si contiene
SQL, transacciones, cálculos de negocio o varios pasos reutilizables, esas
partes se extraen a la capa correspondiente.

Señales de que una clase o un método mezcla responsabilidades:

- su nombre necesita «Y» para describir lo que hace;
- recibe dependencias de UI, persistencia y dominio a la vez;
- cambia por motivos independientes, como fiscalidad e impresión;
- usa campos privados que solo sirven a subconjuntos inconexos de métodos;
- no puede probarse sin levantar un formulario o una BBDD, aunque su núcleo
  sea un cálculo puro.

La salida preferida es una función pura, un `TGestorXxx`, un servicio de
dominio, una estrategia o un adaptador de persistencia. Cada colaborador
nuevo tiene responsabilidad, consumidor, propietario y ciclo de vida
explícitos. No se crean clases auxiliares sin una frontera real.

Los límites y la forma de extraer métodos se describen en §14.5. El código
legado que supere los objetivos no se reescribe de golpe: al tocarlo no se
incrementa su tope y, si el alcance lo permite, se extrae un paso cohesivo.

### 14.12 Abierto/cerrado (OCP) y sustitución (LSP)

#### 14.12.1 Extender sin duplicar el flujo

Cuando aparecen variantes del mismo proceso, el flujo estable permanece y
lo variable se expresa mediante:

- un `record` de configuración para tablas, campos, signos y opciones;
- una interfaz de estrategia cuando cambia el comportamiento;
- un registro o factoría en la raíz de composición cuando cambia la clase;
- un evento o callback tipado cuando cambia la reacción del consumidor.

Añadir un tipo de documento no implica copiar un formulario ni ampliar una
cadena de `if` por tipo. Se añade una configuración y, solo si cambia una
regla, una implementación de la estrategia correspondiente. Tampoco se
generalizan dos flujos por parecido superficial: manda el modelo compartido,
como establece §14.6.

No se modifica una abstracción estable para añadir opciones que solo usa un
consumidor. Esa opción pertenece a una configuración específica, a una
interfaz más pequeña o al propio consumidor.

#### 14.12.2 Conservar el contrato de los ancestros

Todo descendiente se puede usar donde se espera su ancestro sin sorpresas.
Un override:

- mantiene las precondiciones; no exige datos adicionales inesperados;
- conserva las postcondiciones y efectos documentados;
- respeta propiedad, liberación, transacción y propagación de errores;
- llama a `inherited;` al principio cuando el contrato base así lo exige;
- no convierte una operación válida del ancestro en un «no soportado»;
- no sobreescribe un hook solo para dejarlo vacío y anular el comportamiento.

Si solo algunos descendientes admiten una capacidad, esa capacidad no se
añade al ancestro común. Se expresa mediante una interfaz pequeña o una
composición que implementan únicamente las clases capaces de cumplirla.

Los contratos polimórficos relevantes tienen pruebas compartidas: la misma
batería se ejecuta contra cada implementación y comprueba resultados,
errores y efectos observables. Probar solo la clase concreta no demuestra
sustituibilidad.

### 14.13 Segregación (ISP) e inversión de dependencias (DIP)

#### 14.13.1 Interfaces diseñadas desde el consumidor

Una interfaz agrupa operaciones que un mismo consumidor necesita juntas; no
publica toda la API de la implementación. Se separan, por ejemplo, lectura,
escritura, caché y compartición si tienen consumidores distintos.

Reglas:

- una interfaz propia no supera 10 métodos;
- lleva GUID y nombres del dominio, no del componente que la implementa;
- no incluye métodos «por si acaso» ni miembros implementados como no-op;
- los contratos de dominio no exponen VCL, DevExpress, UniDAC ni `TDataSet`;
- los datos cruzan la frontera como tipos simples, enumerados o `record`;
- si un objeto ofrece varias capacidades, se inyectan juntas mediante un
  `record TServiciosXxx`, pero cada consumidor conserva solo las que usa.

El límite de diez miembros es un máximo de seguridad, no un objetivo. Si una
interfaz mezcla dos razones de cambio, se divide aunque tenga menos miembros.

#### 14.13.2 Depender de contratos estables

Las reglas de negocio no crean ni buscan sus dependencias. Las reciben por
constructor o por el método que inicia la operación y las guardan en campos
tipados cuando su ciclo de vida abarca varios métodos.

La raíz de composición crea las implementaciones concretas. Los adaptadores
`UniData*` implementan persistencia; las unidades `inLib*` consumen los
contratos `inLib*Intf`. Una unidad de dominio nueva:

- no contiene SQL literal ni conoce nombres de tablas;
- no incluye unidades `UniData*` en ningún `uses`;
- no accede a conexiones, sesión o parámetros globales;
- no usa `Supports` dentro de métodos de negocio;
- falla de forma explícita al faltar una dependencia obligatoria, en vez de
  buscar un singleton o continuar con un valor implícito.

Una dependencia opcional solo es opcional si el dominio define el
comportamiento en su ausencia. Se representa con una estrategia nula
deliberada o una condición explícita en la composición, nunca capturando una
excepción de configuración para seguir silenciosamente.

### 14.14 Clean Code en Object Pascal

#### 14.14.1 Nombres que expresan intención

- Se usa el mismo vocabulario del dominio en BBDD, UI, código y pruebas.
- Un método indica acción y objeto: `CalcularTotalesFactura`,
  `ValidarPeriodoIva`, `GuardarLineasPedido`.
- Un booleano permite leer la condición como una afirmación:
  `EsFacturaEditable`, `TieneLineasPendientes`.
- Se evitan nombres genéricos como `Datos`, `Info`, `Manager`, `Aux` o
  `Proceso` si no concretan la responsabilidad.
- Las abreviaturas se limitan a las ya establecidas por el proyecto y el
  dominio. La coherencia no justifica crear una abreviatura nueva ambigua.

El nombre y la firma deben explicar el propósito sin necesitar un comentario.
Los comentarios explican decisiones, restricciones o motivos, como indica
§13.

#### 14.14.2 Métodos y nivel de abstracción

Un método representa un paso nombrable y mantiene un nivel de abstracción.
No mezcla, por ejemplo, la decisión «materializar sesión» con asignaciones de
parámetros UniDAC y cambios de foco en controles.

- Las consultas devuelven información y no cambian estado observable.
- Los procedimientos que cambian estado lo expresan con un verbo claro.
- Los efectos laterales relevantes aparecen en la firma, el nombre o el
  contrato; no se esconden dentro de una función de consulta.
- Cuando una firma acumula muchos parámetros relacionados, se usa un
  `record` de entrada o configuración con nombre de dominio.
- Un booleano que selecciona dos algoritmos suele sustituirse por un
  enumerado, dos métodos con intención clara o una estrategia.
- Al alcanzar un tercer nivel de anidación, se revisa la extracción de una
  condición o un paso. No se usa `Exit` para disimular la complejidad.
- Un handler VCL recoge valores, llama a una operación y presenta el
  resultado. Si supera 15 líneas efectivas, se extrae la coordinación.
- Un método normal no supera 60 líneas efectivas. Superar 40 obliga a
  comprobar que conserva una única responsabilidad y nivel de abstracción.
- Los métodos fiscales, de caja y transaccionales no superan 10 decisiones.
- Las firmas nuevas no acumulan más de cinco parámetros independientes. Los
  valores que forman una entrada cohesiva viajan en un `record`.

Se prefieren condiciones positivas y bloques acotados. Una expresión
compleja que representa una regla se extrae a un método booleano con nombre
de dominio.

#### 14.14.3 Acoplamiento y encapsulación

Una clase pide a un colaborador que realice una operación; no navega por sus
detalles internos para hacerla desde fuera. Las cadenas largas del tipo
`A.B.C.D` son una señal de conocimiento excesivo y se encapsulan detrás de
una operación con intención.

- No se accede a campos `F*` de otra clase.
- No se expone un componente visual o dataset solo para que otra capa lo
  manipule.
- Los campos son privados; se publica la mínima operación necesaria.
- La propiedad del recurso y quién lo libera quedan claros al crearlo.
- No se guarda una referencia más tiempo del que permite su propietario.
- Un colaborador de aplicación no recibe un formulario concreto ni usa
  `with FAnfitrion do`. Recibe una vista mínima, callbacks tipados o valores.
- Una extracción no se considera desacoplamiento si la nueva clase conserva
  acceso completo al objeto original y puede manipular todos sus campos.

#### 14.14.4 Literales, mensajes y código muerto

- Los mensajes visibles y textos traducibles son `resourcestring` en el
  catálogo `inLibMsg*` del dominio correspondiente.
- Las constantes de dominio tienen nombre; no se repiten números, estados o
  cadenas con significado de negocio dentro de métodos.
- Los nombres de campo SQL repetidos usan las constantes de §11.
- Los valores cerrados se modelan con enumerados; no con cadenas libres.
- El código sin uso, los parámetros obsoletos y los bloques comentados se
  eliminan. Git conserva el historial.

No se crea una constante para ocultar un literal obvio y local, como cero en
un contador. Se nombra cuando el valor tiene significado o se repite como
parte de una regla.

#### 14.14.5 Errores y resultados

Una operación termina con un resultado válido o informa de que no pudo
completarse. No devuelve un valor aparentemente correcto después de un
fallo.

- Las excepciones representan fallos excepcionales, no bifurcaciones
  habituales del negocio.
- Los rechazos esperables usan un resultado tipado cuando el llamador debe
  decidir cómo mostrarlos.
- Un `except` solo captura cuando puede añadir contexto, recuperar el flujo
  o traducir la excepción; en otro caso se deja propagar.
- No se mezclan `Boolean`, mensajes y excepciones para representar el mismo
  fallo en distintas implementaciones de un contrato.
- No se deduce un estado buscando palabras dentro de un mensaje de error.
  Cancelación, conflicto, ausencia y validación se representan con
  enumerados, excepciones específicas o resultados tipados.
- Una dependencia, dataset o campo obligatorio falla inmediatamente con
  contexto suficiente. `FindField` solo tolera ausencia cuando el contrato
  declara expresamente el campo como opcional.
- La firma o documentación del contrato indica quién posee y libera listas,
  streams, datasets, conexiones, workers y demás objetos no gestionados.

### 14.15 Regla del boy scout y trinquetes de calidad

Al tocar código legado se deja la zona un poco mejor, pero dentro del alcance
del cambio. Se puede renombrar una variable confusa, extraer una condición o
eliminar un `uses` muerto. No se mezcla una reorganización masiva con un
cambio funcional.

Los topes de calidad son trinquetes: pueden bajar, nunca subir. No se cambia
un máximo, una exclusión o una lista blanca para hacer pasar código nuevo. Si
una excepción arquitectónica fuera realmente necesaria, se documenta la
decisión y se acuerda antes de modificar el comprobador.

El estilo legado se congela además por unidad en
`scripts/estilo_linea_base.csv`. Una unidad nueva entra sin `Exit`,
`Continue`, `with`, líneas de más de 80 columnas ni tabuladores. Una unidad
existente no puede superar ninguna de sus medidas. Después de reducir deuda,
la línea base se baja con:

```powershell
.\scripts\comprobar_estilo_codigo.ps1 -ActualizarLineaBase
```

La actualización toma el mínimo entre la medida guardada y la actual: no
puede utilizarse para aceptar una regresión.

La codificación también es un trinquete. Todo archivo nuevo usa UTF-8 con
BOM y CRLF. Si un archivo legado tiene una excepción y se normaliza, ese
cambio se hace en un commit mecánico separado cuando la conversión genere un
diff amplio. Una modificación funcional no añade nuevas excepciones ni
mezcla una normalización masiva que impida revisar el comportamiento.

La entrada única para ejecutar todos los resguardos es:

```powershell
.\scripts\comprobar_calidad.ps1
```

La batería completa en un equipo con Delphi se ejecuta en Release para Win32
y Win64:

```powershell
.\scripts\ejecutar_pruebas_delphi.ps1
```

`.github/workflows/calidad.yml` ejecuta los trinquetes y sus pruebas en cada
push y pull request. La opción manual `ejecutar_delphi` añade DUnitX en un
runner propio con las etiquetas `Windows` y `Delphi`. Ese runner debe usar
GitHub Actions Runner 2.329.0 o posterior, requisito de `actions/checkout@v6`.

Los resguardos principales cubren:

| Objetivo | Comprobadores |
|----------|---------------|
| Capas y DIP | `comprobar_dependencias_capas`, `comprobar_sql_en_dominio`, `comprobar_estado_global` |
| SRP | `comprobar_tamano_clases`, `comprobar_flujos_largos`, `comprobar_formularios_delgados` |
| ISP e inyección | `comprobar_interfaces_segregadas`, `comprobar_supports` |
| Clean Code | `comprobar_estilo_codigo`, `comprobar_metodos_largos`, `comprobar_codificacion` |
| Persistencia segura | `comprobar_sql_transacciones` |

Que los scripts terminen correctamente es necesario, pero no suficiente. La
revisión también comprueba nombres, cohesión, contrato de los descendientes,
efectos laterales y que las pruebas cubran el comportamiento modificado.

### 14.16 Criterio P5 para código nuevo y legado modificado

P5 distingue entre el objetivo de excelencia y los topes temporales que
permiten migrar el legado sin una reescritura masiva:

| Aspecto | Código nuevo | Legado modificado |
|---------|--------------|--------------------|
| Handler VCL | Hasta 15 líneas efectivas | No crece; se extrae coordinación |
| Método normal | Hasta 60; objetivo menor de 40 | No crece; si supera 120, reduce una medida |
| Decisiones en zona fiscal/caja | Hasta 10 | No aumenta y se cubre con caracterización |
| Anidación | Hasta 2 niveles | No se añade un nivel nuevo |
| `Exit`, `Continue`, `with` | Cero | No aumentan; se retiran en la zona tocada |
| Dependencias | Explícitas y mínimas | No se introduce búsqueda global nueva |
| Pruebas | Éxito, límites y fallos relevantes | Prueba de caracterización antes de extraer |
| Codificación | UTF-8 con BOM y CRLF | Sin excepciones nuevas; normalización separada |

Las líneas efectivas son las comprendidas entre `begin` y `end`, sin contar
líneas vacías ni comentarios aislados. Las decisiones son las que informa
`comprobar_metodos_largos.ps1`. Hasta que exista un límite automático más
estricto, los valores de esta tabla se comprueban también en revisión.

Una pieza cumple P5 cuando puede leerse de arriba abajo, sus dependencias se
ven en la firma o constructor, sus efectos están expresados, el error no se
convierte en éxito y su núcleo se prueba sin levantar la VCL ni una BBDD.

---

## 15. Manías y convenciones particulares del autor

Estas son convenciones que ya están en el código y que conviene
**preservar** para no introducir variaciones cosméticas:

1. **`inherited;` en su propia línea** al principio de los handlers
   sobreescritos, antes de cualquier lógica añadida.
2. **Doble paréntesis** en condiciones compuestas — se mantiene para
   legibilidad, no se "limpia":
   ```pascal
   if ((sPref = 'ES') or (iLen = 20)) then
   ```
3. **`Self.` explícito** cuando se accede a propiedades del propio
   formulario desde un método (`Self.pkFieldName`, `Self.Owner`). Es
   redundante en Delphi pero el código lo usa por claridad.
4. **Sin `with` nuevo**: siempre se nombra el receptor. El legado se retira
   gradualmente al tocar la unidad:
   ```pascal
   oDataSet := tvLineasFacturacion.DataController.DataSet;
   ShowMto(
     Self.Owner,
     'Articulos',
     oDataSet.FieldByName('CODIGO_ART_FACLIN').AsString);
   ```
5. **Mensajes de UI siempre en español** y con tildes correctas:
   `'IBAN Validado OK'`, no `'IBAN OK'` ni `'IBAN valid'`.
6. **Strings con SQL** se construyen por concatenación con espacios al
   principio de cada línea, para que el SQL siga siendo legible:
   ```pascal
   unqryCliPrint.SQL.Text :=
     'SELECT CODIGO_CLI, NOMBRE_CLI ' +
     '  FROM vi_clientes ' +
     ' WHERE CODIGO_CLI = :CODIGO';
   ```
7. **Parámetros SQL en mayúsculas**: `:CODIGO`, `:NUMERO`. Coincide con la
   convención de la BBDD.
8. **Nombres compuestos pegados en mayúsculas** cuando reflejan una columna
   de BBDD: `txtRAZONSOCIAL_CLIENTE` (no `txtRAZON_SOCIAL_CLIENTE`).
9. **`FreeAndNil` sobre `Free`** — siempre.
10. **Pantallas auto-registradas en su propia unidad** por referencia de
    clase, no mediante RTTI construido con cadenas ni catálogos agregadores.

---

## 16. Anti-patrones (lista negra)

```
✗  TForm como ancestro directo de un formulario
✗  Componentes con nombre auto-generado (cxGridDBColumn37, Panel2, pnl1)
✗  Free sin FreeAndNil
✗  Variables locales sin prefijo de tipo en código nuevo
✗  CamelCase en nombres de columna en código (FieldByName('codigoCli'))
✗  Comentar código viejo "por si acaso"
✗  Líneas de más de 80 columnas
✗  Mezclar tabs y espacios (solo espacios)
✗  Mensajes de UI en inglés
✗  Estado global mutable, incluso dentro de inLibGlobalVar
✗  Variables globales frmMtoXxx o dmmXxx en código nuevo
✗  Unidades inLib* o UniData* usando unidades inMto*
✗  Unidades inLib* usando unidades UniData*
✗  Librerías que instancian un repositorio en vez de recibirlo
✗  Fachadas inLib* que solo re-exportan tipos de UniData*
✗  SQL literal nuevo dentro de una unidad inLib*
✗  Contratos de dominio que exponen VCL, DevExpress, UniDAC o TDataSet
✗  Interfaces con más de 10 métodos o con miembros que el consumidor no usa
✗  Supports dentro de un método de negocio o como localizador de servicios
✗  uses circulares — romper moviendo a uses de implementation
✗  Nombres de unidad con tilde o eñe en el fichero
✗  TForm con código de negocio: la lógica va a inLib*
✗  Data modules que cambian pestañas, foco o controles visuales
✗  Modales que conocen al formulario que los abrió
✗  Resolver clases por RTTI a partir de cadenas de BBDD
✗  Identificar ventanas por Caption o ClassName
✗  Añadir handlers de menú que solo llaman a ShowMto
✗  Métodos nuevos de más de 200 líneas
✗  Handlers VCL nuevos de más de 15 líneas efectivas
✗  Métodos nuevos de más de 60 líneas sin dividir pasos cohesivos
✗  Métodos fiscales, de caja o transaccionales con más de 10 decisiones
✗  with en código nuevo
✗  Colaboradores que reciben el formulario completo como anfitrión
✗  Extracciones que solo trasladan el monolito a una clase con back-reference
✗  Overrides vacíos o que invalidan una operación admitida por el ancestro
✗  Funciones de consulta con efectos laterales ocultos
✗  Copiar un formulario o ampliar if por tipo para añadir una variante
✗  SQL con valores de usuario concatenados
✗  except vacío o que convierte un fallo en éxito silencioso
✗  Inferir estados de negocio buscando texto dentro de un mensaje de error
✗  Ignorar con FindField la ausencia de un campo obligatorio
✗  Contratos sin propiedad clara de listas, streams, datasets o workers
✗  Componentes VCL o conexiones compartidas con un hilo trabajador
✗  Llamar a inherited al final del handler; va al principio
✗  Acceder a campos privados (F*) de otra clase
✗  Aumentar un tope o una lista blanca para aceptar una regresión nueva
```

La separación de capas y su comprobación automática se describen en §14.1.

---

## 17. Cómo crear una unidad nueva — plantillas

### 17.1 Mantenimiento nuevo

1. Crea `src/Forms/inMtoXxx.pas` y `.dfm`.
2. Hereda de `TfrmMtoGen`.
3. Crea data module `src/DataModules/UniDataXxx.pas` heredando de
   `TdmBase`, con `unqryTablaG` apuntando a la tabla nueva.
4. Sobreescribe `CrearTablaPrincipal` y solo los hooks necesarios.
5. Añade ambas unidades al `.dpr` y al `.dproj`.
6. Auto-registra cada clase en el `initialization` de su propia unidad.
7. Configura `fza_winforms` y asigna `MenuGenericoClick` al ítem si solo
   abre la pantalla. No añadas un handler específico a `inMtoPrincipal`.
8. Añade pruebas para toda regla de dominio nueva.

Esqueleto mínimo:

```pascal
{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifas                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de tarifas comerciales.                                     }
{******************************************************************************}

unit inMtoTarifas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms,
  inMtoGen, UniDataTarifas;

type
  TfrmMtoTarifas = class(TfrmMtoGen)
    // componentes...
  private
    FDataModule: TdmTarifas;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

{$R *.dfm}

procedure TfrmMtoTarifas.CrearTablaPrincipal;
begin
  inherited;
  FDataModule := tdmDataModule as TdmTarifas;
  Self.pkFieldName := 'CODIGO_TAR';
end;

procedure TfrmMtoTarifas.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

end.
```

Y en el catálogo:

```pascal
initialization
  RegistrarPantalla(TfrmMtoTarifas);
  RegistrarDataModule(TdmTarifas);
end.
```

### 17.2 Modal nuevo

```pascal
unit inMtoModalConfirmarBorrado;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  inMtoFrmBase, cxButtons, cxLabel;

type
  TConfirmarBorradoResult = record
    Aceptado : Boolean;
    Motivo   : string;
  end;

  TfrmModalConfirmarBorrado = class(TfrmBase)
    pnlBody    : TPanel;
    pnlButtons : TPanel;
    btnAceptar : TcxButton;
    btnCancelar: TcxButton;
    lblPregunta: TcxLabel;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FResultado : TConfirmarBorradoResult;
  public
    class function Ejecutar(
      AOwner          : TComponent;
      const APregunta : string
    ): TConfirmarBorradoResult;
  end;

implementation

{$R *.dfm}

class function TfrmModalConfirmarBorrado.Ejecutar(
  AOwner          : TComponent;
  const APregunta : string): TConfirmarBorradoResult;
var
  oFormulario: TfrmModalConfirmarBorrado;
begin
  oFormulario := TfrmModalConfirmarBorrado.Create(AOwner);
  try
    oFormulario.lblPregunta.Caption := APregunta;
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalConfirmarBorrado.btnAceptarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := True;
  Close;
end;

procedure TfrmModalConfirmarBorrado.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := False;
  Close;
end;

end.
```

### 17.3 Librería nueva

```pascal
unit inLibCalculoMargen;

interface

type
  TEntradaCalculoMargen = record
    PrecioCoste: Currency;
    PorcentajeMargen: Double;
  end;
  TResultadoCalculoMargen = record
    EsValido: Boolean;
    PrecioSalida: Currency;
  end;
  TCalculadorMargen = class
  public
    class function Calcular(
      const AEntrada: TEntradaCalculoMargen):
      TResultadoCalculoMargen;
  end;

implementation

class function TCalculadorMargen.Calcular(
  const AEntrada: TEntradaCalculoMargen):
  TResultadoCalculoMargen;
begin
  Result := Default(TResultadoCalculoMargen);
  Result.EsValido := AEntrada.PrecioCoste >= 0;
  if Result.EsValido then
  begin
    Result.PrecioSalida := AEntrada.PrecioCoste *
      (1 + (AEntrada.PorcentajeMargen / 100));
  end;
end;

end.
```

Una librería de dominio nueva no recibe `TUniQuery`, `TDataSet` ni nombres
de columnas. Si necesita persistencia, el contrato vive en `inLib*Intf`, la
librería recibe esa interfaz y el adaptador se implementa en `UniData*`.

---

## 18. Sistema de fotos (artículo / SKU)

Subsistema transversal para asociar imágenes a artículos y SKUs con
fallback al padre (análogo al de tarifas). Lo usa cualquier pantalla que
trabaje con artículos o SKUs, y los informes FastReport vía nombres
reservados.

### 18.1 Modelo de almacenamiento

**BBDD** — tabla `fza_articulos_fotos` (DDL en
`DESARROLLOS EN CURSO/fotos_articulos.sql`):

| Columna | Significado |
|--------|-------------|
| `CODIGO_ART_FOT`       | FK lógica `fza_articulos.CODIGO_ART_ART`     |
| `CODIGO_UNIDAD_FOT`    | FK lógica `fza_articulos_skus.CODIGO_UNIDAD_SKU`. `''` = foto a nivel artículo |
| `NOMBRE_FOT_FOT`       | Nombre base del fichero (sin extensión, con sufijo `_NNN`) |
| `EXTENSION_ORIGEN_FOT` | Extensión del fichero original sin punto (`png`, `jpg`, …) |
| `INSTANTE_ALTA / INSTANTE_MODIF / USUARIO_ALTA / USUARIO_MODIF` | metadatos estándar |

PK compuesta `(CODIGO_ART_FOT, CODIGO_UNIDAD_FOT)`. La vista
`vi_articulos_fotos` expone el fallback resuelto por SKU.

**Disco** — los ficheros viven bajo el parámetro `appDirFotos`, **todos
como PNG** (el original se re-encodifica a PNG sin perder dimensiones):

```
<appDirFotos>/300/<NOMBRE_FOT_FOT>.png    PNG redimensionado a 300 px (lado mayor)
<appDirFotos>/600/<NOMBRE_FOT_FOT>.png    PNG redimensionado a 600 px (lado mayor)
<appDirFotos>/real/<NOMBRE_FOT_FOT>.png   PNG en resolución original (sin redimensionar)
```

El redimensionado se hace con GDI (`StretchBlt` + `HALFTONE` sobre
`TBitmap pf32bit`). El "real" no es una copia byte-a-byte del fichero
fuente: se carga el grafico (PNG / JPG / BMP) y se vuelve a guardar
como PNG manteniendo las dimensiones — así los tres se tratan igual,
sin diferencias de extensión ni de codec a la hora de cargar.

No hay BLOBs en BBDD — la tabla solo guarda metadatos
(`NOMBRE_FOT_FOT`, `EXTENSION_ORIGEN_FOT` se conserva como
traza informativa del fichero subido pero ya no se usa para componer
la ruta en disco).

### 18.2 Convención de nombre de fichero

Formato canónico:

```
<CLAVE>_<NNN>
```

- `<CLAVE>` = `CODIGO_UNIDAD_SKU` si la fila es de SKU, en otro caso
  `CODIGO_ART_ART`. Los caracteres problemáticos para el sistema de
  ficheros (`/ \ : * ? " < > |`) se sustituyen por `_`. Ejemplo:
  `BLUS-SEDA/BLANCO/L` → `BLUS-SEDA_BLANCO_L`.
- `<NNN>` = índice numérico de 3 dígitos con relleno (`001`, `002`, …).
  Incrementa **en cada guardado y en cada rotación**. Los ficheros del
  índice anterior se borran tras la escritura del nuevo. El cambio de
  nombre invalida cualquier caché por nombre (FastReport en particular).

### 18.3 Fallback de resolución (jerárquico)

`oFotos.Resolver(CODIGO_ART, CODIGO_UNIDAD_SKU)` aplica una cascada de
más específico a más general:

1. **Match exacto del SKU** — fila con `CODIGO_UNIDAD_FOT = SKU`.
2. **Match por prefijo** — el SKU se trocea por `/` y se prueban
   prefijos sucesivamente más cortos, mientras quede al menos un `/`.
   Por ejemplo, para `BLUS-SEDA/BLANCO/L`:
   - intenta `BLUS-SEDA/BLANCO/L` (exacto)
   - intenta `BLUS-SEDA/BLANCO` (prefijo)
   - se para porque `BLUS-SEDA` ya no tiene `/`
3. **Match a nivel artículo** — fila con `CODIGO_UNIDAD_FOT = ''`.
4. **Primera foto por color** — cuando no se proporciona SKU y no existe
   foto general, primera fila ordenada por `CODIGO_UNIDAD_FOT`.
5. Nada — `Encontrada = False`.

La consulta SQL hace los pasos 1 y 2 con un solo `WHERE CODIGO_UNIDAD_FOT
IN (...)` ordenado por `LENGTH(CODIGO_UNIDAD_FOT) DESC LIMIT 1`. El paso
3 es una segunda consulta. El paso 4 permite que el mantenimiento de
artículos muestre una foto representativa aunque todas las disponibles sean
por color.

`TFotoInfo.Origen` deja constancia:
- `foSku`        : fila exacta del SKU completo
- `foSkuPrefijo` : fila con un prefijo del SKU
- `foArticulo`  : fila con `CODIGO_UNIDAD_FOT = ''`
- `foSinFoto`   : no se encontró nada

Y `TFotoInfo.ClaveResuelta` guarda el `CODIGO_UNIDAD_FOT` exacto que
matcheó. Es lo que la UI usa para `Eliminar` y `Rotar` cuando hay que
operar sobre la fila resuelta, no sobre el SKU original.

El helper `GenerarPrefijosSku(ACodSku)` devuelve la lista de claves
candidatas en orden de especificidad. Lo usa la pantalla para poblar
el combo de niveles.

### 18.4 API pública — `inLibFotos`

`TFotosArticulos` es una fachada creada por la raíz de composición. Esta le
entrega los repositorios y servicios mediante `AsignarConexion`, y la fachada
delega en colaboradores de consulta, edición, almacenamiento físico, sesión y
presentación. Los consumidores pueden seguir usando `inLibFotos` mientras se
migran gradualmente a contratos más pequeños.

```pascal
// Resolver con fallback
function Resolver(const ACodArt, ACodSku: string): TFotoInfo;

// Ruta absoluta de la foto resuelta en una resolución
function RutaFoto(const AInfo: TFotoInfo;
                  AResolucion: TFotoResolucion): string;

// Importa una foto desde disco. Genera 300/600/real y avanza el índice.
function Guardar(const ACodArt, ACodSku,
                 AFicheroOrigen: string): TFotoInfo;

// Rota 90° las tres copias en sentido horario / anti-horario y avanza
// índice. La fila de BBDD afectada es la del nivel resuelto: si la foto
// venía heredada del artículo, rota la del artículo (no crea una nueva
// fila de SKU).
function Rotar(const ACodArt, ACodSku: string;
               AHorario: Boolean): TFotoInfo;

// Borra fila y ficheros. Solo borra si la fila resuelta era exactamente
// la del nivel pedido (un SKU heredado no se "auto-rompe" desde otro SKU).
procedure Eliminar(const ACodArt, ACodSku: string);
```

`ACodSku = ''` → operación a nivel artículo.

Constantes para los nombres de columna en la propia unit (`fcodartfot`,
`fnomfot`, etc.) — el mismo patrón de §11.

### 18.5 Formulario flotante — `frmFotoArticulo`

Vive en `src/Forms/inMtoFotoArticulo.pas`. **No es modal**:

```pascal
FormStyle := fsStayOnTop;
Position  := poScreenCenter;
KeyPreview := True;
```

Render por **GDI** vía `TImage` + `Vcl.Imaging.PngImage` (no
`cxImage`).

Singleton via variable global `frmFotoArticulo`. Al cerrarse se libera
(`Action := caFree`) y la variable vuelve a `nil`, de modo que la
siguiente invocación crea una instancia limpia.

**Layout**:

```
pnlTop          alTop, h=38     barra superior fija
├── btnToggle   "▼ Controles" / "▲ Controles" — toggle del panel
└── lblOrigen   texto descriptivo de la foto resuelta
pnlControles    alTop, h=180, Visible=False por defecto
├── rgResolucion (300 / 600 / Real)
├── lblNivel + cbbNivelSku (SKU completo y sus prefijos)
├── btnCambiarArt, btnCambiarSku, btnQuitar
└── btnRotarIzq, btnRotarDer
pnlImage        alClient        ocupa todo el resto
└── imgFoto     alClient, Proportional + Stretch
```

Por defecto `pnlControles.Visible = False` → la foto ocupa toda la
ventana excepto la barra superior. Al pulsar **▼ Controles** (o **F11**)
el panel se despliega; un nuevo click lo vuelve a encoger.
`alClient` hace el ajuste automático sin animación intermedia.

**Persistencia de geometría**: `Alt + F12` invoca `GuardarLayout`, que
delega en `TLayoutSaver.GuardarGeometria(Self)` y luego
`PreguntarYGrabar` para que el usuario elija ámbito (igual patrón que
`inMtoConsultaOpe`). En `FormShow` se crea un `TLayoutLoader` que
restaura `Left / Top / Width / Height / WindowState` si el usuario los
guardó previamente.

**Auto-refresh**. Cuando se invoca desde un `TfrmMtoGen` vía
`Ctrl + Alt + F`, la pantalla queda enganchada al `dsTablaG` del Mto
mediante `VincularMtoPadre(ADataSource, AResolver)`. Encadena
`OnDataChange`: ante cada cambio de registro activo (`Field = nil`),
vuelve a llamar a `AResolver` y recarga la foto. Al cerrarse o al
re-engancharse a otro Mto, restaura el handler previo de
`OnDataChange` para no romper la lógica del Mto.

Helper de invocación:

```pascal
procedure MostrarFotoFlotante(AOwner: TComponent;
                              const ACodArt, ACodSku: string);
```

Crea la pantalla si no existe, refresca el par (art, sku) y la trae al
frente. No engancha por sí solo el auto-refresh; eso lo hace el
llamador con `frmFotoArticulo.VincularMtoPadre(...)` (lo hace
`inMtoGen.FormKeyDown` justo después de llamar al helper).

Para usarse **dentro de otro modal** (donde un Show queda detrás) hay un
wrapper en `src/Modals/inMtoModalFotoArticulo.pas` con la firma canónica
`class function Ejecutar`:

```pascal
TfrmModalFotoArticulo.Ejecutar(AOwner, ACodArt, ACodSku);
```

Internamente crea el mismo `TfrmFotoArticulo` con `FormStyle := fsNormal`
y `ShowModal`.

### 18.6 Atajo `Ctrl + Alt + F`

Gestionado en `TfrmMtoGen.FormKeyDown` — disponible en **cualquier Mto**
que herede de `TfrmMtoGen`. Llama a `ResolverArtSkuActivo(out ACodArt,
out ACodSku)` para sacar el par del registro activo de `dsTablaG`.

`ResolverArtSkuActivo` es `virtual`. La implementación por defecto recorre
una lista de alias habituales:

```pascal
CODIGO_ART_ART, CODIGO_ART_SKU, CODIGO_ART_FAC, CODIGO_ART_FACLIN,
CODIGO_ART_PEDLIN, CODIGO_ART_ARTTAR, CODIGO_ARTICULO
CODIGO_UNIDAD_SKU, CODIGO_UNIDAD_FAC, CODIGO_UNIDAD_FACLIN,
CODIGO_UNIDAD_PEDLIN, CODIGO_UNIDAD_ARTTAR
```

**Cuándo sobreescribirlo**: cuando el artículo activo no está en
`dsTablaG` sino en un sub-grid (el caso más común para documentos
maestro-detalle: `inMtoFacturas`, `inMtoTarifas`, `inMtoPedidos`,
`inMtoAlbaranes`). Para esos casos basta delegar en
`LeerArtSkuDeDataSet` pasando el DataSet del grid de detalle:

```pascal
procedure TfrmMtoFacturas.ResolverArtSkuActivo(out ACodArt,
                                               ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';  ACodSku := '';
  if Assigned(tvLineasFactura.DataController.DataSource) then
  begin
    ds := tvLineasFactura.DataController.DataSource.DataSet;
    LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);  // recorre los alias
  end;
end;
```

`LeerArtSkuDeDataSet` (también público en `TfrmMtoGen`) recorre los
alias canónicos: `CODIGO_ART_ART`, `CODIGO_ART_SKU`, `CODIGO_ART_FAC`,
`CODIGO_ART_FACLIN`, `CODIGO_ART_PEDLIN`, `CODIGO_ART_ALBLIN`,
`CODIGO_ART_ARTTAR`, `CODIGO_ARTICULO` y los equivalentes de
`CODIGO_UNIDAD_*`.

Estado actual de los overrides en el código:

| Mto                       | Sub-grid de detalle    | Tabla                          |
|---------------------------|------------------------|--------------------------------|
| `inMtoFacturas`           | `tvLineasFactura`      | `fza_facturas_lineas`          |
| `inMtoTarifas`            | `tvArticulos`          | `fza_articulos_tarifas`        |
| `inMtoPedidos`            | `tvPedidosLineas`      | `fza_pedidos_lineas`           |
| `inMtoAlbaranes`          | `tvLineasAlbaran`      | `fza_albaranes_lineas`         |
| `inMtoComprasSesiones`    | `tvLineas`             | `fza_compras_sesiones_lineas` (artículo **tentativo**, ver §18.11) |

`LeerArtSkuDeDataSet` ahora vive como función pública libre en
`inLibFotos` (no como método de `TfrmMtoGen`), de modo que también es
invocable desde formularios que no heredan de `TfrmMtoGen` — como
`inMtoCajaOpe` o `inMtoConsultaOpe`. La lista de alias canónicos
(`cAliasArt`, `cAliasSku`) es **single source of truth**: la usa la
función pública, la usa la sustitución en FastReports y la usan los
overrides. Para añadir una columna nueva (p.ej. una nueva tabla
maestra), basta meter el alias en la constante.

### 18.7 FastReports — sustitución de imágenes

En `TfrmPrint.AfterReportLoaded` (`inMtoModalGenImp`) se invoca
`SustituirFotosEnReport(frxrprt1)`. La función recorre
`Report.AllObjects` y, para cada `TfrxPictureView` cuyo `Name` sea
exactamente `foto300`, `foto600` o `fotoReal` (case-insensitive), carga
la foto del par (artículo, sku) que se obtiene de la **banda padre** de
la imagen:

- Sube por `pic.Parent` hasta encontrar `TfrxDataBand`.
- Lee el `TDataSet` asociado a esa banda.
- Busca los campos siguiendo la misma lista de alias que
  `ResolverArtSkuActivo`.

**Limitación conocida**: en esta versión de FastReport, `OnBeforePrint`
de `TfrxView` es una propiedad `string` (nombre de un proc del script
del informe) y no un evento Delphi nativo, por lo que la sustitución se
hace una sola vez antes de `PrepareReport`. Cubre informes de un solo
registro (ficha, vista previa, ticket). Para informes iterativos con
foto distinta por banda habría que pasar a un esquema con scripts
inyectados + user-function — está documentado en
`DESARROLLOS EN CURSO/fotos_articulos.md` como pendiente.

**Reglas para los diseñadores de informes**:

- Para mostrar foto, añadir un `TfrxPictureView` y nombrarlo
  exactamente `foto300`, `foto600` o `fotoReal`.
- La imagen debe vivir dentro de una banda cuyo `DataSet` tenga columnas
  con los alias de artículo/SKU reconocidos.
- No usar otros nombres y luego escribir scripts a mano: el subsistema
  ignora cualquier nombre que no sea uno de los tres reservados.

### 18.8 Parámetro de aplicación

Categoría `Directorios`, clave `appDirFotos`. Registrado en
`inLibAppParam.InicializarParametrosApp` con valor por defecto
`$(PUBLICO)\Factuzam\fotos` — token resuelto por
`inLibPathTokens.ExpandPathTokens` a `CSIDL_COMMON_DOCUMENTS`
(`C:\Users\Public\Documents` en Windows estándar). Lo elegimos público
porque las fotos son un recurso compartido entre todos los usuarios de
la máquina, no un dato personal.

Configurable desde `frmMtoAppParam`. Para una instalación multi-puesto
se recomienda apuntarlo a una ruta UNC compartida (p.ej.
`\\servidor\factuzam\fotos`); el subsistema funciona idénticamente con
cualquier ruta resoluble por el filesystem de Windows.

Los subdirectorios `300/`, `600/`, `real/` se crean automáticamente en
el primer `oFotos.Guardar`.

### 18.9 Formularios fuera de `TfrmMtoGen`

Algunos formularios heredan de `TfrmBase` directamente (la pantalla
operativa de caja, la consulta de operaciones) y no se benefician del
`Ctrl + Alt + F` heredado. Se integran a mano según convenga:

**`TfrmMtoOpeCaja` (caja operaciones) — foto embebida en el panel de
stock**. No usa la pantalla flotante: incrustamos un `TImage` en el
panel `pnlBusqueda` (a la derecha del grid `cxgrdStock`) con
`Proportional + Stretch + Center`. Siempre se carga la copia 300 px
del par (artículo, sku) de la línea activa. Refresco vía hook directo
de `dsLineas.OnDataChange`:

```pascal
procedure TfrmMtoOpeCaja.DsLineasDataChange(Sender: TObject; Field: TField);
begin
  if Field = nil then
    RefrescarFotoStock;   // cambio de registro activo
end;

procedure TfrmMtoOpeCaja.RefrescarFotoStock;
// ... lee CODIGO_ART_FACLIN / CODIGO_UNIDAD_FACLIN del dataset activo,
//     resuelve via oFotos.Resolver, carga imgFotoStock con la 300 px ...
```

Encaje del DFM: `pnlFotoStock: TPanel; Align = alRight; Width = 120`
dentro de `pnlBusqueda`. El grid `cxgrdStock` con `Align = alClient` se
reduce automáticamente.

**`TfrmConsultaOpe` (consulta de operaciones) — Ctrl + Alt + F a mano**.
Tiene un `FormKeyDown` propio donde se intercala el atajo. Lee de la
línea de factura activa (`FdmConsulta.dsFacturaLin.DataSet`) y llama a
`MostrarFotoFlotante` + `VincularMtoPadre`. El patrón es idéntico al de
`TfrmMtoGen.FormKeyDown`, solo que la fuente del par (art, sku) la
provee un método privado `ResolverArtSkuDeFacLin`.

Cualquier otro formulario que quiera incorporar fotos sigue uno de los
dos patrones: foto embebida (más cómoda cuando la pantalla ya es ancha
y hay sitio fijo) o atajo + flotante (más rápido cuando el caso de uso
es esporádico).

### 18.10 Resumen de unidades implicadas

| Unidad                                   | Carpeta            | Rol                                      |
|------------------------------------------|--------------------|------------------------------------------|
| `inLibFotos`                             | `src/Lib/`         | Fachada compatible y composición de colaboradores |
| `inLibFotosTipos`                        | `src/Lib/`         | Tipos compartidos y contrato de lectura para presentación |
| `inLibFotosConsulta`                     | `src/Lib/`         | Resolución jerárquica, lotes, caché y lectura de alias |
| `inLibFotosEdicion`                      | `src/Lib/`         | Guardado, rotación y eliminación de fotos de artículos |
| `inLibFotosAlmacenamiento`               | `src/Lib/`         | PNG físico, tamaños, nombres, rotación y borrado |
| `inLibFotosSesion`                       | `src/Lib/`         | Fotos temporales y materialización de sesiones de compra |
| `inLibFotosPresentacion`                 | `src/Lib/`         | Foto VCL embebida y sustitución en FastReport |
| `inLibFotosPersistenciaIntf`             | `src/Lib/`         | Contratos segregados de persistencia |
| `UniDataFotosRepositorio`                | `src/DataModules/` | Adaptadores UniDAC de los contratos de persistencia |
| `inMtoFotoArticulo`                      | `src/Forms/`       | Pantalla flotante (no modal)             |
| `inMtoModalFotoArticulo`                 | `src/Modals/`      | Wrapper modal con `class function Ejecutar` |
| `inMtoGen` (modificada)                  | `src/Forms/`       | Atajo Ctrl + Alt + F, `ResolverArtSkuActivo` virtual y `LeerArtSkuDeDataSet` |
| `inMtoFacturas` (modificada)             | `src/Forms/`       | Override de `ResolverArtSkuActivo` sobre `tvLineasFactura` |
| `inMtoTarifas` (modificada)              | `src/Forms/`       | Override de `ResolverArtSkuActivo` sobre `tvArticulos` |
| `inMtoPedidos` (modificada)              | `src/Forms/`       | Override de `ResolverArtSkuActivo` sobre `tvPedidosLineas` |
| `inMtoAlbaranes` (modificada)            | `src/Forms/`       | Override de `ResolverArtSkuActivo` sobre `tvLineasAlbaran` |
| `inMtoComprasSesiones` (modificada)      | `src/Forms/`       | Override de `ResolverArtSkuActivo` sobre `tvLineas` (artículo tentativo) |
| `inMtoCajaOpe` (modificada)              | `src/Forms/`       | Foto embebida en panel de stock (sin Ctrl + Alt + F) |
| `inMtoConsultaOpe` (modificada)          | `src/Forms/`       | Ctrl + Alt + F sobre línea de factura |
| `inMtoModalGenImp` (modificada)          | `src/Modals/`      | `AfterReportLoaded` llama a `SustituirFotosEnReport` |
| `inLibAppParam` (modificada)             | `src/Lib/`         | Registro de `appDirFotos` |
| `fotos_articulos.sql`                    | `DESARROLLOS EN CURSO/` | DDL de la tabla y la vista |
| `fotos_sesiones.md`                      | `DESARROLLOS EN CURSO/` | Diseño pendiente para fotos pre-materialización (§18.11) |

---

### 18.11 Sesiones de compras — fotos pre-materialización (pendiente)

En `inMtoComprasSesiones` los artículos son **tentativos**: el código
`CODIGO_ART_TENTATIVO_SESLIN` solo se materializa en `fza_articulos`
al cerrar la sesión (`InLibComprasSesionesMaterializar`). El subsistema
de fotos actual exige fila previa en `fza_articulos`, así que **no se
puede subir foto durante la captura**.

Solución diseñada (pendiente de implementar) en
`DESARROLLOS EN CURSO/fotos_sesiones.md`:

1. Tabla `fza_compras_sesiones_fotos` paralela, claveada por
   `(SERIE, NUMERO, LINEA, CODIGO_UNIDAD)`.
2. Ficheros bajo `appDirFotos` con prefijo
   `ses_<SERIE>_<NUMERO>_<LINEA>_<NNN>.png` para no chocar.
3. API en `oFotos.GuardarSesion / ResolverSesion`.
4. En la materialización, `MigrarFotosSesion(...)` mueve cada fila a
   `fza_articulos_fotos` con el código real y renombra los PNG.

Hoy el Mto solo tiene el override de `ResolverArtSkuActivo` —
`Ctrl + Alt + F` muestra la pantalla flotante y permite *ver* fotos de
artículos ya creados, pero subir desde una línea de sesión todavía no
funciona porque la FK lógica contra `fza_articulos` no se cumple.

---

## 19. Sistema de log y errores

Subsistema transversal para diagnosticar fallos y trazar actividad del
usuario sin recompilar. Se controla por completo desde **Parámetros
Generales** (`frmMtoAppParam`) y los cambios se aplican en caliente.

El singleton `Log` se conserva como fachada de compatibilidad para código
legado e infraestructura. El código nuevo de dominio o aplicación recibe
`IRegistroLog` desde `inLibLogIntf` y registra mediante ese contrato. No usa
`Log` como dependencia oculta.

Las unidades implicadas son:

| Unidad                  | Carpeta            | Rol                                                                                  |
|-------------------------|--------------------|--------------------------------------------------------------------------------------|
| `inLibLogIntf`          | `src/Lib/`         | Contrato pequeño `IRegistroLog` para dominio y aplicación                            |
| `inLibLog`              | `src/Lib/`         | Implementación, fachada legado, niveles, rotación y mutex entre procesos              |
| `inLibAppParam`         | `src/Lib/`         | Registra los 4 parámetros booleanos y llama a `AplicarFlagsLog` tras `Recargar`      |
| `UniDataConn`           | `src/DataModules/` | `UniSQLMonitor1SQL` cronometra cada query y la vuelca con `LogSQLExt`                |
| `inMtoFrmBase`          | `src/Core/`        | `DoShow` / `DoClose` autologuean apertura y cierre de cualquier formulario           |
| `UniDataGen`            | `src/DataModules/` | `BeforeInsert` / `BeforePost` autologuean alta y modificación del dataset principal  |
| `inMtoPrincipal`        | `src/Core/`        | `Application.OnException := AppException` — captura global de excepciones no atrapadas |
| `inMtoAppParam`         | `src/Core/`        | Al guardar parámetros invoca `inLibLog.AplicarModosDepuracion` para refrescar flags  |

### 19.1 Niveles de log

```pascal
TLogType = (ltInfo, ltWarning, ltError, ltSQL, ltPerf, ltAvanzado);
```

| Nivel        | Para qué                                                            | API                  |
|--------------|---------------------------------------------------------------------|----------------------|
| `ltInfo`     | Mensajes informativos (arranque, hitos del flujo)                   | `Log.LogInfo`        |
| `ltWarning`  | Avisos no fatales (recursos opcionales no disponibles, fallback)    | `Log.LogWarning`     |
| `ltError`    | Fallos. Siempre activo. `AppException` escribe aquí                 | `Log.LogError`       |
| `ltSQL`      | Sentencias SQL con tiempo, filas y OK/ERR                           | `Log.LogSQLExt` (auto desde `UniDataConn`); `Log.LogSQL` para volcado crudo |
| `ltPerf`     | Cronómetros de operaciones largas (`[PERF:tag] detalle | N ms`)     | `Log.LogPerf`        |
| `ltAvanzado` | Eventos de UI / dataset (`EVT: unidad | objeto | evento | detalle`) | `Log.LogEvento`      |

`ltInfo`, `ltWarning` y `ltError` están **siempre encendidos**. Los
otros tres se controlan con los flags de §19.2.

### 19.2 Flags de activación (Parámetros Generales)

Hay dos categorías de switches:

**Categoría "Depuración"** — switches "gordos":

| Clave              | Enciende                                  |
|--------------------|-------------------------------------------|
| `appModoDebug`     | `ltPerf` + `ltSQL` + detalle MySQL en `conUniError` |
| `appModoDebugSQL`  | `ltSQL` (solo SQL, sin cronómetros)       |

**Categoría "Log"** — controles finos:

| Clave            | Enciende      |
|------------------|---------------|
| `appLogSQL`      | `ltSQL`       |
| `appLogAvanzado` | `ltAvanzado`  |

La aplicación de los flags está centralizada en
`inLibLog.AplicarModosDepuracion` (único *source of truth*). Se invoca:

1. En `TfrmMtoPrincipal.FormCreate` (arranque, en cuanto `oAppParams`
   está cargado).
2. En `TfrmMtoAppParam` al guardar parámetros.
3. A través de `TAppParams.Recargar` → `AplicarFlagsLog` (que delega).

En compilaciones `{$IFDEF DEBUG}` el modo SQL queda forzado a `True`
independientemente de los flags.

### 19.3 Qué se loguea automáticamente

Si tu unidad hereda de la base correcta y usa el dataset principal del
patrón, **no tienes que escribir nada**: el log ya cubre lo siguiente.

| Heredas de…   | Te logueas gratis                                                                  |
|---------------|------------------------------------------------------------------------------------|
| `TfrmBase`    | `EVT: <UnitName> | <ClassName> | Show | <Name>` y el equivalente `Close`           |
| `TfrmMtoGen`  | Lo de `TfrmBase` (encadena por `inherited`)                                        |
| `TdmBase`     | `EVT: <UnitName> | <DataSet.Name> | BeforeInsert | ''` (solo `unqryTablaG`)        |
| `TdmBase`     | `EVT: <UnitName> | <DataSet.Name> | BeforePost | state=<estado>` (`unqryTablaG` y `unqryPerfiles`) |
| Toda query sobre la conexión principal | `SQL: [OK|ERR] N ms | filas=- | <sentencia>` vía `UniSQLMonitor1` |
| Toda excepción no atrapada      | `ERROR: AppException <Clase>: <Mensaje>` + diálogo modal con detalle copiable     |

Reglas que esto impone al código nuevo:

- **Formularios**: heredar de `TfrmBase`, `TfrmMtoGen` o derivado.
  Nunca de `TForm` (ya estaba en §1.4 y §4.1, ahora también por log).
- **Data modules**: heredar de `TdmBase`. El dataset principal se llama
  `unqryTablaG` (§5.4 y §10.3). Si lo renombras, pierdes el autolog de
  `BeforeInsert` / `BeforePost`.
- **Queries**: usar `ConexionPrincipal` en formularios y módulos base, o
  recibir `AConexion: TUniConnection` / `IServicioConexiones` de forma
  explícita en librerías (§14.2). No acceder a `dmConn` ni introducir
  conexiones globales.
- **Excepciones**: si las dejas subir sin `try/except`, las captura el
  manejador global. Solo envuelve en `try/except` cuando vas a reaccionar
  (§12.2). El comportamiento por defecto es el correcto.

### 19.4 Qué hay que loguear a mano

El autolog cubre la "actividad de fondo". Para el resto, llama
explícitamente desde tu unidad. Estos son los puntos típicos.

#### 19.4.1 Cronómetros (`LogPerf`)

Cuando una operación pueda tardar lo suficiente como para que importe
medirla (consulta agregada, exportación, materialización de sesión,
proceso por lotes…), envuelve en `TStopwatch`:

```pascal
uses System.Diagnostics, inLibLog;

procedure TdmFacturas.CargarLineasDeFactura(const ASerie: string;
                                            ANumero: Integer);
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    unqryLineasFac.Close;
    unqryLineasFac.ParamByName('SERIE').AsString  := ASerie;
    unqryLineasFac.ParamByName('NUMERO').AsInteger := ANumero;
    unqryLineasFac.Open;
  except
    on E: Exception do
    begin
      Log.LogError('CargarLineasDeFactura: ' + E.Message);
      raise;   // siempre raise tras loguear (§12.2)
    end;
  end;
  Log.LogPerf('Facturas.CargarLineasDeFactura',
              Format('serie=%s nro=%d filas=%d',
                     [ASerie, ANumero, unqryLineasFac.RecordCount]),
              sw.ElapsedMilliseconds);
end;
```

El log queda como `[PERF:Facturas.CargarLineasDeFactura] serie=A nro=42
filas=18 | 73 ms`. Solo se escribe si `appModoDebug` está encendido.

Sitios habituales donde añadir `LogPerf` en una unidad nueva:

- `AfterOpen` / `AfterScroll` del `unqryTablaG` si abren detalles
  pesados (patrón actual en `UniDataArticulos`, `UniDataFacturas`).
- Procedimientos de negocio largos en el data module (consolidaciones,
  cálculos de stock, generaciones de pedidos…).
- Materializaciones / exportaciones / impresiones (`inLib*`).

#### 19.4.2 Eventos relevantes (`LogEvento`)

El autolog cubre Show/Close/Insert/Post. Si en tu unidad hay otra
acción de usuario que merezca aparecer en la traza avanzada (un
diálogo modal con resultado, un click en un botón de acción
significativo, una operación que dispara efectos colaterales), llámalo:

```pascal
Log.LogEvento(Self.UnitName, Self.ClassName, 'MaterializarCompras',
              Format('serie=%s nro=%d lineas=%d',
                     [sSerie, iNumero, iLineas]));
```

Patrón: `(UnitName, identificador del objeto, nombre de evento, detalle)`.
El detalle es opcional. Solo se escribe si `appLogAvanzado` está activo.

#### 19.4.3 Errores controlados (`LogError`)

Cuando hagas `try/except` para reaccionar localmente, loguea el error y
**vuelve a lanzar**:

```pascal
try
  // ...
except
  on E: Exception do
  begin
    Log.LogError(Self.UnitName + '.' + 'NombreDelMetodo: ' + E.Message);
    raise;
  end;
end;
```

El `raise;` es obligatorio si la operación no se considera completada
(criterio de modest-fermat-WUvkF para evitar dejar queries colgadas).
Solo se omite si la excepción es genuinamente recuperable y la
operación puede seguir.

#### 19.4.4 Avisos (`LogWarning`)

Para condiciones inesperadas pero no fatales: un parámetro huérfano,
un fichero opcional ausente, una conversión que recurre a un valor por
defecto. Que la operación pueda seguir, pero quede traza:

```pascal
if not FileExists(sLogo) then
  Log.LogWarning('Logo de empresa no encontrado: ' + sLogo);
```

#### 19.4.5 Información de hitos (`LogInfo`)

Para marcar el inicio y fin de procesos largos o cambios de estado
globales. Úsalo con moderación: el archivo de log lo lee gente, no
solo `grep`.

```pascal
Log.LogInfo('Inicio de cierre de caja ' + sCodCaja);
```

### 19.5 API rápida

API preferida para código nuevo:

```pascal
uses inLibLogIntf;

FRegistroLog.RegistrarInformacion(AMensaje);
FRegistroLog.RegistrarAviso(AMensaje);
FRegistroLog.RegistrarError(AMensaje);
FRegistroLog.RegistrarRendimiento(AEtiqueta, ADetalle, ADuracionMs);
```

La interfaz se recibe por constructor o composición. La siguiente API
concreta queda para infraestructura y migración de consumidores existentes:

```pascal
uses inLibLog;

Log.LogInfo   (const AMessage: string);
Log.LogWarning(const AMessage: string);
Log.LogError  (const AMessage: string);
Log.LogSQL    (const ASQL: string);                            // crudo
Log.LogSQLExt (const ASQL: string; AElapsedMs: Int64;          // detallado
               ARows: Integer; AOk: Boolean;
               const AError: string = '';
               const AParams: string = '');
Log.LogPerf   (const ATag, ADetalle: string; AElapsedMs: Int64);
Log.LogEvento (const AUnidad, AObjeto, AEvento, ADetalle: string);

// Encender / apagar un nivel a mano (raro: lo normal es vía parámetros).
Log.EnableLogType(ltAvanzado);
Log.DisableLogType(ltAvanzado);
Log.IsLogTypeEnabled(ltSQL): Boolean;
```

Los ficheros se generan en `GetLogFolder` con nombre
`LOG_<yyyy_mm_dd_hhnnss>_<UUID>.log` para que ordenen por fecha. Cuando
el contador de ficheros supera `DEFAULT_LOG_RETENTION` (10), se zippean
los más antiguos en `archive/<yyyy>/<mm>/Logs_<yyyy-mm-dd>.zip`. La
rotación se hace al arrancar. En ese mismo momento, los ZIP del formato
anterior `archive/Logs_<yyyymmdd_hhnnss>.zip` se trasladan y consolidan
en el ZIP diario correspondiente.

### 19.6 Sistema de errores — `AppException`

Definido en `TfrmMtoPrincipal` y enganchado vía
`Application.OnException := AppException` en `FormCreate`. Captura
**cualquier** excepción no atrapada por bloques `try/except` y:

1. Construye un detalle completo (`ConstruirDetalleException`):
   aplicación + versión, fecha, usuario, empresa, almacén, caja,
   equipo, clase y mensaje de la excepción, dirección (`ExceptAddr`),
   sender, stack trace (si hay proveedor — `madExcept`/`JCL`/`EurekaLog`),
   y hasta 5 niveles de `InnerException`.
2. Lo vuelca al log con `LogError` (dos líneas: cabecera + detalle).
3. Abre un diálogo modal (`MostrarDetalleExcepcion`) con el detalle en
   un `TMemo` Consolas + botón **Copiar al portapapeles** para pegarlo
   en un reporte.

Implicación práctica para una unidad nueva:

- **No reinventes manejadores globales.** Tu unidad no asigna nada a
  `Application.OnException`; ya está cubierto.
- **Tu `try/except` solo cubre la reacción local.** El detalle completo
  ya lo da el manejador global si dejas subir la excepción.
- **No engulláis excepciones.** Un `except on E: Exception do end;` sin
  `raise;` ni `Log.LogError` rompe la traza global y deja la operación
  en estado inconsistente.

El handler se desinstala en `FormDestroy`
(`Application.OnException := nil`) para que el shutdown ordenado no
intente mostrar diálogos sobre un form ya liberado.

### 19.7 Checklist al añadir una unidad nueva

- [ ] El dominio y la aplicación reciben `IRegistroLog`; no introducen una
      llamada nueva al singleton `Log`.
- [ ] El formulario hereda de `TfrmBase` o derivado → autolog Show/Close.
- [ ] El data module hereda de `TdmBase` y su query principal se llama
      `unqryTablaG` → autolog BeforeInsert/BeforePost.
- [ ] Las queries usan `ConexionPrincipal` o una conexión recibida por
      contrato; ninguna unidad introduce una conexión global.
- [ ] Operaciones que puedan tardar > 100 ms instrumentadas con
      `Log.LogPerf` y `TStopwatch`.
- [ ] Eventos relevantes del dominio (no triviales) con `Log.LogEvento`.
- [ ] `try/except` añadidos por necesidad loguean con `Log.LogError` y
      hacen `raise;` salvo que la operación sea genuinamente recuperable.
- [ ] No se asigna nada a `Application.OnException` — está reservado.

---

## 20. Formato automatico de columnas en grids dinamicos

En los formularios de **busqueda** (`TfrmMtoSearch` y descendientes) las
columnas del grid principal se crean a vuelo de pajaro, recorriendo
`unqryTablaG.Fields` con `cxGrdDBTabPrin.CreateColumn`. Eso deja la
columna con `PropertiesClass = nil` (que cxGrid renderiza como
`TcxTextEditProperties`), asi que un campo `PRECIO_VENTA_ART` sale como
texto plano y un `ESACTIVO_CLI` aparece literalmente como `'S'` o `'N'`.

Para evitar configurar la columna a mano en cada Mto, `inLibDevExp.pas`
expone `AplicarPropertiesPorPrefijo(AView)`, que recorre las columnas
del view y asigna `PropertiesClass` segun el **prefijo del campo**,
siguiendo la convencion del `LIBRO_DE_ESTILO_BBDD.md` §3.2.

### 20.1 Mapa de prefijo a properties

| Prefijo del campo                | PropertiesClass                | DisplayFormat                  |
|----------------------------------|--------------------------------|--------------------------------|
| `PRECIO_*` / `TOTAL_*` / `IMPORTE_*` | `TcxCurrencyEditProperties` | `#,##0.00 "€";-#,##0.00 "€";0.00 "€"` |
| `PORCENTAJE_*`                   | `TcxCurrencyEditProperties`    | `#,##0.00 "%";-#,##0.00 "%";0.00 "%"` |
| `VALOR_*` / `CANTIDAD_*`         | `TcxCurrencyEditProperties`    | `#,##0.##;-#,##0.##;0`         |
| `ES*` (con TField `varchar(1)`)  | `TcxCheckBoxProperties`        | `ValueChecked='S'`, `ValueUnchecked='N'` |

`UseDisplayFormatWhenEditing = True` para que el formato persista al
entrar en edicion de celda.

### 20.2 Prefijos que NO se tocan (y por que)

| Prefijo / convencion         | Tipo BBDD     | Resultado por defecto                |
|------------------------------|---------------|--------------------------------------|
| `NUMERO_*` / `LINEA_*` / `CONTADOR_*` | `varchar` | Texto plano — es un identificador (`"F2026-0042"`), no un numero. |
| `ORDEN_*`                    | `int(11)`     | cxGrid asigna `TcxSpinEditProperties` por el `TIntegerField`. |
| `FECHA_*`                    | `date`        | cxGrid asigna `TcxDateEditProperties` por el `TDateField`. |
| `INSTANTE_*` (incluidas las 4 de auditoria) | `datetime` | cxGrid asigna `TcxDateEditProperties` por el `TDateTimeField`. |
| `USUARIO_ALTA` / `USUARIO_MODIF` | `varchar(50)` | Texto plano. |

### 20.3 Salvaguarda: respetar lo del .dfm

La rutina **solo asigna properties si la columna no tiene ya un
`PropertiesClassName` propio** (vacio o `TcxTextEditProperties`). Si el
diseñador puso `TcxLookupComboBoxProperties` en el .dfm para una
columna `CODIGO_TAR_*`, no se pisa.

### 20.4 Donde se llama automaticamente

`TfrmMtoSearch.CrearTablaPrincipal` (`src/Forms/inMtoGenSearch.pas`)
la invoca al final, despues de crear las columnas y antes de
`ApplyBestFit`. Eso cubre todos los Mtos que se lanzan via
`TBusquedaUtils.EjecutarBusqueda` (F3 de articulos, busqueda de
clientes, etc).

`PonerAnchosTitulos` (que corre despues, en `AplicarEtiquetas`)
restaura `Caption`/`Width`/`Visible`/`Sort` del perfil del usuario pero
**no toca `PropertiesClass`**, asi que el formato sobrevive.

### 20.5 Como invocarla en otros mantenimientos

Si un Mto normal (no de busqueda) tiene columnas dinamicas con campos
sin properties, basta con llamarla manualmente tras crear las columnas
o al final de `AplicarEtiquetas`:

```pascal
uses inLibDevExp;

procedure TfrmMtoMisCosas.CrearTablaPrincipal;
begin
  inherited;
  // ... crear columnas dinamicas ...
  AplicarPropertiesPorPrefijo(cxGrdDBTabPrin);
end;
```

Funciona con cualquier descendiente de `TcxCustomGridTableView`
(incluido `TcxGridDBBandedTableView`). No es necesario llamarla en
Mtos cuyas columnas estan completamente cableadas desde el .dfm — solo
tiene efecto sobre las que esten "sin properties".

### 20.6 Como añadir un prefijo nuevo

Cuando aparezca un prefijo de columna nuevo en `LIBRO_DE_ESTILO_BBDD.md`
§3.2 que merezca formato automatico:

1. Edita `AplicarPropertiesPorPrefijo` en `src/Lib/inLibDevExp.pas`.
2. Añade el prefijo al array `PRE_DINERO` / `PRE_PORC` / `PRE_NUM`
   correspondiente, o crea una nueva categoria con su formato.
3. Si requiere una `PropertiesClass` distinta a las tres ya soportadas
   (Currency / CheckBox), añade un helper `SetXxxProps` siguiendo el
   patron de `SetCurrencyProps` / `SetCheckBoxProps`.
4. Actualiza la tabla §20.1 de este documento.

---

## 21. Checklist antes de un commit

- [ ] Cabecera de unidad presente y con la fecha correcta.
- [ ] Nombre de unidad y nombre de fichero coinciden.
- [ ] Ninguna línea > 80 columnas.
- [ ] Indentación de 2 espacios, sin tabuladores.
- [ ] Sin componentes auto-numerados (`Panel2`, `cxGridDBColumn37`).
- [ ] Hereda de la base correcta (`TfrmMtoGen`, `TfrmBase`, `TdmBase`).
- [ ] Campos declarados antes que métodos dentro de cada sección de clase.
- [ ] `FreeAndNil` para todo recurso creado.
- [ ] Nombres de columna SQL en mayúsculas, tal cual viven en la BBDD.
- [ ] Sin estado global mutable ni nuevas variables `frmMtoXxx`/`dmmXxx`.
- [ ] Cada unidad, clase y método modificado conserva una responsabilidad
      principal y un nivel de abstracción coherente.
- [ ] Los handlers visuales coordinan; no contienen SQL, transacciones ni
      reglas de negocio reutilizables.
- [ ] Las dependencias obligatorias entran por constructor, herencia o
      parámetro explícito; no se buscan durante el trabajo.
- [ ] Las interfaces responden a un consumidor, no superan 10 métodos y no
      filtran tipos de infraestructura al dominio.
- [ ] Los descendientes conservan precondiciones, resultados, errores y
      efectos definidos por el ancestro.
- [ ] Las variantes nuevas usan configuración, estrategia o registro, sin
      copiar formularios ni cadenas de condiciones por tipo.
- [ ] Si es Mto: `CrearTablaPrincipal` y solo los hooks necesarios.
- [ ] Si es Mto: clases auto-registradas en sus propias unidades.
- [ ] Si abre desde menú: usa `MenuGenericoClick`, salvo lógica adicional.
- [ ] Si es modal: expone `class function Ejecutar(...)`.
- [ ] El modal no conoce al formulario llamador.
- [ ] Ningún `inLib*`/`UniData*` usa una unidad `inMto*`.
- [ ] SQL parametrizado; transacciones completas en escrituras múltiples.
- [ ] Sin `except` vacío, `Exit`, `Continue` ni instrucciones en la línea
      del `if`, `while` o `for`.
- [ ] Handlers VCL nuevos de hasta 15 líneas efectivas: recogen, invocan y
      presentan.
- [ ] Métodos normales nuevos de hasta 60 líneas, preferiblemente menos de
      40, y con un único nivel de abstracción.
- [ ] Métodos fiscales, de caja o transaccionales con un máximo de 10
      decisiones y pruebas de error/rollback.
- [ ] Ningún colaborador recibe un formulario completo ni conserva una
      back-reference para manipular su estado interno.
- [ ] Nombres expresivos, sin efectos laterales ocultos ni literales de
      negocio repetidos.
- [ ] Estados y errores tipados; no se interpretan buscando texto en
      mensajes.
- [ ] Campos y dependencias obligatorios fallan inmediatamente; `FindField`
      solo se usa como opcional cuando el contrato lo declara.
- [ ] Propiedad y liberación de listas, streams, datasets, conexiones y
      workers están definidas.
- [ ] Los textos visibles nuevos son `resourcestring` del catálogo de su
      dominio.
- [ ] Pruebas DUnitX/SQL añadidas o actualizadas cuando corresponda.
- [ ] `scripts\comprobar_calidad.ps1` termina correctamente y no se han
      elevado topes ni añadido excepciones para hacerlo pasar.
- [ ] La aplicación y DUnitX compilan y pasan en las plataformas afectadas;
      para cambios transversales, Release Win32 y Win64.
- [ ] Los archivos nuevos usan UTF-8 con BOM y CRLF; una normalización
      masiva se entrega separada del cambio funcional.
- [ ] Comentarios en español, sin código muerto comentado.
- [ ] Si tocas la BBDD, el cambio cumple `LIBRO_DE_ESTILO_BBDD.md`.
