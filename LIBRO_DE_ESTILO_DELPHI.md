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
5. **Los nombres de columna SQL viajan tal cual** desde la BBDD al código:
   `FieldByName('CODIGO_CLI_CLI')`, nunca traducidos ni camelizados.
6. **Sin notación húngara para tipos de control** (no `TfrmMtoClientes` para
   un panel): los prefijos de control (`btn`, `lbl`, `txt`...) indican el
   tipo VCL, no el tipo lógico. Para variables locales sí se usa prefijo
   corto de tipo (`s`, `i`, `b`, `o`).
7. **Todos los dfm se guardan como utf8 con BOM**, y también los pas y dpr.
8. **Acentos dentro de dfm y pas se ponen nativos áéñ y no como ansi (old legacy)**.
---

## 2. Estructura de directorios

```
src/
├── Core/           Formularios troncales: Logon, Principal, Splash,
│                   AppParam, CajaParam, PreviewExcel, PreviewTicket,
│                   y el base inMtoFrmBase
├── Forms/          Formularios de mantenimiento (Mtos) y derivados
├── Modals/         Formularios modales reutilizables
├── DataModules/    Data modules UniDAC (UniData*)
├── Lib/            Unidades sin formulario: lógica, utilidades, helpers
├── Lib3par/        Wrappers de bibliotecas de terceros (recopilatorio)
├── vcl/ vcl37/     Forks/parches locales de VCL por versión
├── verifactu/      Subsistema Verifactu (AEAT)
├── 3rdpartyComp/   Componentes de terceros pinchados en el repo
└── utilnormbbdd/   Herramienta auxiliar (normalizador de BBDD)
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
| `inLib*`     | Librería / utilidades sin formulario   | `inLibFacturas`, `inLibIBAN`, `inLibUser`, `inLibGlobalVar` |
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
| `TfrmBase`      | `TForm`          | Base raíz (solo localización)    |
| `TfrmMtoGen`    | `TfrmBase`       | Base de todos los mantenimientos |
| `TfrmMto<X>`    | `TfrmMtoGen`     | Mantenimiento concreto           |
| `TfrmModal<X>`  | `TfrmBase`       | Modal/diálogo                    |
| `TfrmPrint<X>`  | `TfrmBase`       | Pantallas de impresión           |
| `TdmBase`       | `TDataModule`    | Base de data modules             |
| `Tdm<X>`        | `TdmBase`        | Data module concreto             |

### 4.2 Variable global de instancia

Sigue la convención de Delphi: variable global con la primera letra en
minúscula, mismo nombre que la clase sin la `T`.

```pascal
TfrmMtoClientes = class(TfrmMtoGen) ... end;

var
  frmMtoClientes: TfrmMtoClientes;
```

Para data modules el patrón es `dmm<Dominio>` (memoria histórica:
*data module mantenimiento*):

```pascal
TdmClientes = class(TdmBase) ... end;

var
  dmmClientes: TdmClientes;
```

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

---

## 5. Prefijos de componente (en `.dfm` y como campos de la clase)

Todos los componentes visuales o no visuales **llevan prefijo de tipo en
minúscula**. Si el componente está ligado a un campo de la BBDD, el
**sufijo del campo va en MAYÚSCULAS** (ver §5.2).

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

  // 3. Unidades del proyecto (orden: base → libs → otras)
  inMtoFrmBase,
  inLibGlobalVar, inLibUser,
  UniDataConn;
```

En la práctica los `.pas` generados por el IDE no respetan la separación
con comentarios; **no merece la pena reordenarlos a mano** salvo que estés
limpiando un fichero. Sí merece la pena:

- Pasar las dependencias del proyecto al final del `uses` de `interface`.
- Mover a `uses` de `implementation` cualquier dependencia que solo se
  usa en `procedure`/`function`, especialmente para romper referencias
  circulares entre Mtos.

### 7.2 Anti-patrón: dejar las skins inflando el `uses`

DevExpress añade ~50 unidades `dxSkin*` cada vez que se abre un form en el
IDE. Es ruido inevitable; no se borra porque rompe la previsualización,
pero **no añade líneas más** por encima de las que ya hay.

---

## 8. Indentación, espacios y ancho

### 8.1 Reglas duras

- **2 espacios** por nivel de indentación. Nunca tabuladores.
- **80 columnas máximo** por línea. Si te pasas, parte (ver §8.2).
- Una sentencia por línea. Nada de `if x then y else z;` en una línea
  excepto guardas triviales (`if Assigned(o) then Exit;`).
- `begin` en línea propia, alineado con la palabra clave que lo abre.

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
unqryTablaG.Connection           := inLibGlobalVar.oConn;
unqryPedidosLineas.Connection    := inLibGlobalVar.oConn;
unqryLinPedido.Connection        := inLibGlobalVar.oConn;
unqryEmpDataPedido.Connection    := inLibGlobalVar.oConn;
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
| `o`     | objeto                | `oConn`, `oCliente`               |
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

Cuatro métodos públicos canónicos heredados o sobreescritos:

```pascal
type
  TfrmMtoClientes = class(TfrmMtoGen)
    // componentes...
  public
    procedure CrearTablaPrincipal; override;  // engancha datasources
    procedure ResetForm; override;            // vuelve a pestaña por defecto
  end;
```

`CrearTablaPrincipal` siempre:

```pascal
procedure TfrmMtoClientes.CrearTablaPrincipal;
begin
  inherited;
  dmmClientes := tdmDataModule as TdmClientes;
  tvFacturacion.DataController.DataSource := dmmClientes.dsFacturasClientes;
  ...
  Self.pkFieldName := 'CODIGO_CLI_CLI';   // PK lógica para el Mto base
end;
```

### 10.2 Formulario modal (`TfrmModal<X>`)

Patrón: **constructor de clase `Ejecutar`** que crea, configura, muestra y
libera el formulario, devolviendo un record con el resultado:

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
res := TfrmModalCalcularMargen.Ejecutar(Self, oConn, idArttar, ...);
if res.Aceptado then
  ...
```

Esta variante evita exponer `frmModalXxx.ShowModal` en cada llamador.

### 10.3 Data module (`Tdm<X>`)

- Hereda de `TdmBase`.
- Su query principal se llama **siempre** `unqryTablaG`.
- Asocia todas las conexiones a `inLibGlobalVar.oConn` en `DataModuleCreate`.
- Métodos de servicio en `PascalCase`: `GetCodigoAutoCliente`,
  `CrearDataSetEtiquetas(iNroEspaciosBlanco: Integer; sCodCli: string)`.

```pascal
procedure TdmClientes.DataModuleCreate(Sender: TObject);
begin
  unqryTablaG.Connection := inLibGlobalVar.oConn;
  unqryFacturasClientes.Connection := inLibGlobalVar.oConn;
  ...
end;
```

### 10.4 Truco de `ForceReferenceToClass`

Para asegurar que el linker no descarta una clase de formulario referida
solo por nombre (registro dinámico de Mtos), cada Mto incluye:

```pascal
procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  ForceReferenceToClass(TfrmMtoClientes);
end.
```

Es boilerplate; al crear un Mto nuevo, copia y cambia el nombre de la
clase.

---

## 11. Constantes para nombres de columna SQL

En cada librería que manipula una tabla, **declarar constantes con el
prefijo `f`** (de *field*) para evitar literales repetidos por toda la
unidad. Pattern: nombre corto en minúsculas, valor = nombre real de la
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

**No** se usan en formularios (los `.dfm` referencian el nombre real por
`DataField`); sí en librerías (`inLib*`) donde el SQL es manipulado por
código.

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

## 14. Constantes globales, variables globales y singletons

- `inLibGlobalVar` es el módulo de **estado global** del programa
  (conexión `oConn`, usuario actual, parametrización en memoria). Toda
  variable global vive ahí; no se crean nuevas variables globales en
  otras unidades.
- Constantes de dominio (porcentajes legales, códigos especiales, claves
  de parametrización) van en la librería del dominio o en
  `inLibGlobalVar` si son transversales.

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
4. **`with` controlado**: se permite `with ... do` solo cuando el bloque
   es corto y la entidad es inequívoca:
   ```pascal
   with tvLineasFacturacion.DataController.DataSet do
     ShowMto(Self.Owner, 'Articulos', FieldByName('CODIGO_ART_FACLIN').AsString);
   ```
5. **Mensajes de UI siempre en español** y con tildes correctas:
   `'IBAN Validado OK'`, no `'IBAN OK'` ni `'IBAN valid'`.
6. **Strings con SQL** se construyen por concatenación con espacios al
   principio de cada línea, para que el SQL siga siendo legible:
   ```pascal
   unqryCliPrint.SQL.Text := ' SELECT * ' +
                             ' from vi_clientes ' +
                             ' where CODIGO_CLI_CLI = :CODIGO';
   ```
7. **Parámetros SQL en mayúsculas**: `:CODIGO`, `:NUMERO`. Coincide con la
   convención de la BBDD.
8. **Nombres compuestos pegados en mayúsculas** cuando reflejan una columna
   de BBDD: `txtRAZONSOCIAL_CLIENTE` (no `txtRAZON_SOCIAL_CLIENTE`).
9. **`FreeAndNil` sobre `Free`** — siempre.
10. **`initialization` con `ForceReferenceToClass`** al final de cada Mto.

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
✗  Variables globales fuera de inLibGlobalVar
✗  uses circulares — romper moviendo a uses de implementation
✗  Nombres de unidad con tilde o eñe en el fichero
✗  TForm con código de negocio: la lógica va a inLib*
✗  Llamar a inherited al final del handler; va al principio
✗  Acceder a campos privados (F*) de otra clase
```

---

## 17. Cómo crear una unidad nueva — plantillas

### 17.1 Mantenimiento nuevo

1. Crea `src/Forms/inMtoXxx.pas` y `.dfm`.
2. Hereda de `TfrmMtoGen`.
3. Crea data module `src/DataModules/UniDataXxx.pas` heredando de
   `TdmBase`, con `unqryTablaG` apuntando a la tabla nueva.
4. Sobreescribe `CrearTablaPrincipal` y `ResetForm`.
5. Añade `ForceReferenceToClass(TfrmMtoXxx)` en `initialization`.
6. Registra el Mto donde corresponda en `inMtoPrincipal` para que el menú
   lo abra.

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
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoTarifas: TfrmMtoTarifas;

implementation

uses
  inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoTarifas.CrearTablaPrincipal;
begin
  inherited;
  dmmTarifas := tdmDataModule as TdmTarifas;
  Self.pkFieldName := 'CODIGO_TAR';
end;

procedure TfrmMtoTarifas.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

initialization
  ForceReferenceToClass(TfrmMtoTarifas);
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
  frm: TfrmModalConfirmarBorrado;
begin
  frm := TfrmModalConfirmarBorrado.Create(AOwner);
  try
    frm.lblPregunta.Caption := APregunta;
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
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
unit inLibMiUtilidad;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, Uni,
  inLibGlobalVar;

const
  fcampoX = 'CAMPO_X_TABLA';

type
  TMiResultado = record
    Ok      : Boolean;
    Mensaje : string;
  end;

  TMiUtilidad = class
  public
    class function Procesar(AQuery: TUniQuery): TMiResultado;
  end;

implementation

class function TMiUtilidad.Procesar(AQuery: TUniQuery): TMiResultado;
begin
  Result.Ok := False;
  Result.Mensaje := '';
  if not Assigned(AQuery) then
    Exit;
  // ... lógica ...
  Result.Ok := True;
end;

end.
```

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
4. Nada — `Encontrada = False`.

La consulta SQL hace los pasos 1 y 2 con un solo `WHERE CODIGO_UNIDAD_FOT
IN (...)` ordenado por `LENGTH(CODIGO_UNIDAD_FOT) DESC LIMIT 1`. El paso
3 es una segunda consulta.

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

Singleton `oFotos: TFotosArticulos` creado en `initialization` de la
unit. Reutiliza `inLibGlobalVar.oConn`.

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
  if Field = nil then RefrescarFotoStock;   // cambio de registro activo
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
| `inLibFotos`                             | `src/Lib/`         | Núcleo: persistencia, redimensionado, rotación, sustitución en informes |
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

Las unidades implicadas son:

| Unidad                  | Carpeta            | Rol                                                                                  |
|-------------------------|--------------------|--------------------------------------------------------------------------------------|
| `inLibLog`              | `src/Lib/`         | Singleton `Log: TLog`, niveles, rotación, mutex entre procesos, `AplicarModosDepuracion` |
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
| Toda query que pase por `oConn` | `SQL: [OK|ERR] N ms | filas=- | <sentencia>` vía `UniSQLMonitor1` |
| Toda excepción no atrapada      | `ERROR: AppException <Clase>: <Mensaje>` + diálogo modal con detalle copiable     |

Reglas que esto impone al código nuevo:

- **Formularios**: heredar de `TfrmBase`, `TfrmMtoGen` o derivado.
  Nunca de `TForm` (ya estaba en §1.4 y §4.1, ahora también por log).
- **Data modules**: heredar de `TdmBase`. El dataset principal se llama
  `unqryTablaG` (§5.4 y §10.3). Si lo renombras, pierdes el autolog de
  `BeforeInsert` / `BeforePost`.
- **Queries**: usar `inLibGlobalVar.oConn` como `Connection` (§10.3).
  Si creas un `TUniConnection` paralelo, su SQL **no** se loguea
  porque `UniSQLMonitor1` está cableado al conn global.
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
`LOG_<UUID>_<dd_mm_yyyy>.log`. Cuando el contador de ficheros supera
`DEFAULT_LOG_RETENTION` (10), se zippean los más antiguos en
`archive/`. La rotación se hace al arrancar.

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

- [ ] El formulario hereda de `TfrmBase` o derivado → autolog Show/Close.
- [ ] El data module hereda de `TdmBase` y su query principal se llama
      `unqryTablaG` → autolog BeforeInsert/BeforePost.
- [ ] Todas las queries usan `inLibGlobalVar.oConn` → autolog SQL con
      cronómetro.
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
- [ ] `FreeAndNil` para todo recurso creado.
- [ ] Nombres de columna SQL en mayúsculas, tal cual viven en la BBDD.
- [ ] Si es Mto: `CrearTablaPrincipal` + `ResetForm` sobreescritos.
- [ ] Si es Mto: `ForceReferenceToClass` en `initialization`.
- [ ] Si es modal: expone `class function Ejecutar(...)`.
- [ ] Comentarios en español, sin código muerto comentado.
- [ ] Si tocas la BBDD, el cambio cumple `LIBRO_DE_ESTILO_BBDD.md`.
