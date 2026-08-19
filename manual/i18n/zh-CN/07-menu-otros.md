# 07 · Otros 菜单

[◀ 返回目录](README.md)

**Otros** 菜单集中提供应用程序的**管理与配置**功能：环境参数、税费、
编号计数器、单据支付方式、安全设置（用户和权限）、备份及高级工具。
这些选项主要供**管理员**使用。

菜单结构：

```
Otros
├── Parámetros del entorno
├── Colas de envíos
│   ├── Verifactu
│   ├── PrestaShop
│   └── Web Service Fzam
├── Grupos de IVA
├── Impuesto IVA
├── Contadores
├── Formas de pago documentos
├── Usuarios, Grupos y Perfiles
│   ├── Usuarios
│   ├── Empleados
│   ├── Grupos
│   ├── Perfiles
│   ├── Permisos
│   └── Permisos (tabla)
├── Hacer Copia de Seguridad
├── Recuperar Copia de Seguridad
├── Generador de Procesos
└── Procesos auxiliares BBDD
```

---

## Parámetros del entorno

![Parámetros Generales de la Aplicación](img/07-parametros.png)

**菜单快捷键：** `[Ctrl]+[F10]`

这是 **Parámetros Generales de la Aplicación** 界面，用于集中管理环境配置：
默认行为、路径、打印和单据选项、当前工作公司的默认值等。每个值都可以
分配给某个用户、某个组或 `Todos`。

常用类别：

| 类别 | 用途 |
|------|------|
| **Directorios / Fotos** | 照片的本地或共享文件夹（`appDirFotos`），以及照片键中使用的属性数量。 |
| **Servicios web** | 照片、邮件、销售、SIF 和盘点共用的 URL（`appApiUrl`）、凭据（`appApiToken`）和安装引用（`appApiReferencia`）；还包括销售队列周期及最大尝试次数。 |
| **Verifactu** | 税务模式、环境、SIF 数据、队列周期、URL，以及签名/时钟参数。 |
| **PrestaShop** | API 连接、店铺、公司、价目表、队列、商品分类层级，以及 **Sincronizar stock y precios**、**Crear artículos en PrestaShop al darlos de alta**、**Activar artículos en PrestaShop al marcar En web** 和 **Hacer barrido periódicamente** 复选框。 |
| **Apariencia** | 界面主题、配色和语言。 |
| **Caja** | TPV 默认值和现金盘点行为。 |

有效值按继承关系解析：先使用**用户**自己的值，再使用其**组**的值，
最后使用 **Todos** 的值。更具体的值会覆盖更通用的值。因此，例如两个组
可以分别使用不同的公司、仓库和 PrestaShop 店铺。每个会话只处理其用户的
有效配置。

对于非根管理员用户，API 密钥会被隐藏。四个复选框默认均不勾选，并且彼此
独立。**Sincronizar stock y precios** 允许更新通过精确且唯一的 `reference`
找到的现有商品。找不到这种对应关系时，**Crear artículos en PrestaShop al
darlos de alta** 会请求完整的新建流程。新建时始终先以 `active=0` 创建商品。
**Activar artículos en PrestaShop al marcar En web**
（`appPrestaShopActivarArticulosAlMarcarWeb`）仅允许在一次正确的新建或同步
流程结束时激活商品；该流程由 **En web** 从 No 改为 Sí 时触发。此参数的
初始值为 `False`。**Hacer barrido periódicamente** 启用每隔数小时执行一次
完整核对；即使未勾选，系统仍会每 60–120 秒恢复待处理任务。

**Niveles de familia a crear (0 = todos)**
（`appPrestaShopNivelesFamiliaAlta`）是一个可继承的整数，初始值为 `0`。
值为 `0` 时导出完整的本地层级；值为正数时，从叶级商品分类开始向上保留
指定层数，并按根 → 叶的顺序创建。PrestaShop 中配置的根分类不计入本地
层级。在 **DEMO-CAMISA** 中，唯一的本地商品分类是 **ROPA**，因此无论
允许值是多少，都只导出这一层。

启用集成前，请按照
[集成检查清单](15-integracion-prestashop.md#14-lista-de-comprobacion-para-una-implantacion)
逐项检查。

### 语言与翻译

语言选择并不是独立菜单项。其准确路径是
**Otros ▸ Parámetros del entorno ▸ Apariencia ▸ Idioma de la interfaz**。
`appIdioma` 参数始终提供西班牙语（`es-ES`）、英国英语（`en-GB`）、
加泰罗尼亚语（`ca-ES`）和简体中文（`zh-CN`），此外还会列出数据库中的
其他已启用语言。`qps-ploc` 保留用于版面测试。

更改语言：

1. 选择要应用该参数的用户、组或作用域。
2. 打开 **Apariencia ▸ Idioma de la interfaz**。
3. 选择语言。对于 `en-GB`、`ca-ES` 或 `zh-CN`，Factuzam 会打开
   **Descargar traducción** 对话框。如果软件包已经安装，系统会复用它；
   否则通过 `appApiUrl` 和 `appApiToken` 从已配置服务获取。
4. 等待检查完成，然后按 **Guardar (F12)**。此时已打开的窗口会更新；
   请关闭并重新打开 Factuzam，以便在整个会话中完整应用更改。

下载过程要求能够连接 Factuzam 服务，并使用具有
`descargar:traducciones` 作用域的令牌。经过身份验证的 ZIP 只有在语言、
合同版本、SQL 顺序与大小，以及每个文件声明的 SHA-256 指纹全部校验通过后
才会安装。架构准备完成后，数据 SQL 会在一个事务中安装。如果下载、验证或
安装失败，系统会保留原来的语言和参数值。

语言设置会影响窗体、菜单、消息、Developer Express 控件，以及具有翻译的
票据和 FastReport 报表。如果缺少键、语言未启用或无法查询数据库，系统会
保留已编译的西班牙语文本作为后备；缺少翻译绝不会使界面内容变为空白。

> `qps-ploc` 会拉长文本并加上标记，帮助开发人员发现被截断的标签。
> 它不是供生产环境使用的语言。

#### 翻译目录管理

翻译保存在中央目录 `fza_traducciones` 中。独立工具
**Editor de traducciones**（`utlTraduc`）允许管理员：

1. 使用 Factuzam 的 INI 文件连接。
2. 同步可执行文件已知的西班牙语文本。
3. 选择一种语言，并显示全部键或只显示待翻译项。
4. 编辑并保存翻译，同时保留 `%s`、`%d` 等占位符。

编辑器还可以接受 `fr-FR` 等新语言标签，而无需修改可执行文件。更改会以
事务方式保存并接受审计。用户在自定义报表格式中手动输入的文本不会自动
翻译。

---

## Grupos de IVA

**菜单快捷键：** `[Ctrl]+[O]`

定义**增值税税率组**（增值税区域/税制），用于为公司、客户和商品关联
相应的一组税率（例如西班牙半岛增值税与其他税制）。

---

## Impuesto IVA

![Tipos de IVA y recargo de equivalencia](img/07-iva.png)

**菜单快捷键：** `[Ctrl]+[I]`

维护具体的**增值税税率**及其百分比（标准税率、低税率、超低税率等），
以及与每种税率关联的**等价附加税**。这是采购和销售税额计算的基础。

> 增值税百分比由法规规定。除非法律发生变化，否则不要修改；税率配置错误
> 会影响所有开票业务。

---

## Contadores

![Contadores de numeración por serie](img/07-contadores.png)

**菜单快捷键：** `[Ctrl]+[R]`

按**系列**和公司管理各类单据（发票、送货单、订单等）的**编号计数器**。
每张单据都从对应计数器取得连续编号。

> 法律要求每个系列的发票编号必须**连续且无空缺**。不要倒退或重复使用
> 发票编号计数器。

---

## Formas de pago documentos

采购和批发销售单据可用的**支付方式**目录（现金、银行转账、若干天后到期
的票据等）。它定义发票、订单和送货单的到期日及收款/付款行为。

主要字段：

| 字段 | 用途 |
|------|------|
| **Número de plazos** | 创建票据或收据时生成的到期批次数量。 |
| **Días entre plazos** | 各到期日之间的间隔。 |
| **% Adelanto** | 预收或预付的部分。 |
| **Ver Banco Empresa en Borrador** | 生成收款或付款时显示公司银行选择。 |
| **Código Facturae** | 签发 eDoc 时使用的官方 `PaymentMeans` 代码（`01` 至 `19`）。 |

子标签页：**Más Datos**、**Ventas**（用于销售）和 **Otros**。

![Formas de pago](img/03-formas-pago.png)

**菜单快捷键：** `[Shift]+[Ctrl]+[G]`

> 此维护界面不同于 **Formas de Pago Caja**；后者用于配置 TPV 的支付按钮
> 和支付类型。

---

## Usuarios, Grupos y Perfiles

**安全**子菜单，用于定义谁可以进入应用程序以及可以执行哪些操作。

### Usuarios

**菜单快捷键：** `[Ctrl]+[H]`

创建和维护可访问 Factuzam 的**用户**，即在
[登录界面](00-acceso-y-primeros-pasos.md)输入凭据的人员。内容包括密码、
状态，以及决定其权限的**配置文件/组**。

### Empleados

*（无菜单快捷键；从菜单打开。）*

维护企业的**员工**资料。员工可以关联到用户和收银操作，从而明确每笔销售
是由**谁**完成的。

### Grupos

**菜单快捷键：** `[Ctrl]+[J]`

使用**用户组**批量分配权限，例如 *Cajeros*、*Administración* 和
*Encargados*。用户会继承所属组的权限。

### Perfiles

**菜单快捷键：** `[Ctrl]+[W]`

通过**配置文件**为用户或组定制界面的外观和行为，例如可见列、标题和选项。

### Permisos

![Gestión de Permisos en árbol](img/07-permisos.png)

**菜单快捷键：** `[Ctrl]+[Q]`

**Gestión de Permisos** 界面以**树形结构**显示权限，可按组/用户启用或
禁用应用程序中每个**菜单和操作**的访问权限。这是以可视方式配置安全设置的
推荐方法。

权限树与应用程序的实际菜单一致，可以：

- 按 **Todos**、组或用户处理。
- 允许、拒绝或继承整个分支。
- 将权限从一个主体复制到另一个主体，并可选择合并或替换。
- 管理菜单权限和界面权限：查询、插入、修改、删除、导出到 Excel 和打印。

在 **Artículos ▸ Activar/desactivar web** 中，专用权限控制谁可以更改商品
资料中的 **En web** 复选框。如果用户没有该权限，复选框将为只读，保存时
也不能更改此标记。

当获授权用户清除 **En web** 时，Factuzam 会询问如何处理：**Sí** 会在
PrestaShop 中停用商品并停止同步；**No** 只停止同步并保留远程状态；
**Cancelar** 不保存更改。选中 **En web** 时，是否远程激活取决于可继承
参数 **Activar artículos en PrestaShop al marcar En web**；若已获授权，
激活只会在正确流程结束时执行。

> 权限更改会在受影响用户下次登录时生效。

### Permisos (tabla)

*（无菜单快捷键；从菜单打开。）*

以**表格格式**（数据网格）显示同一组权限信息，便于批量编辑或快速检查
大量权限。

---

## Colas de envíos

**Otros ▸ Colas de envíos** 路径将三种集成的监控集中在同一位置：

### Verifactu

**路径：** *Otros ▸ Colas de envíos ▸ Verifactu*

显示待处理、处理中、已发送或出错的税务通信。其使用方法和获授权的重新处理
操作请参阅
[Verifactu 章节 · Cola de envíos](11-verifactu.md#cola-de-envios)。

### PrestaShop

**路径：** *Otros ▸ Colas de envíos ▸ PrestaShop*

显示待处理、已处理或出错的商品目录任务，以及每次尝试的 HTTP 历史记录。
这是一个只读诊断界面：不能修改或重试任务。操作详情请参阅
[PrestaShop 集成 ▸ 监控窗口](15-integracion-prestashop.md#ventana-de-seguimiento)。

### Web Service Fzam

**路径：** *Otros ▸ Colas de envíos ▸ Web Service Fzam*

此队列在后台为 **VentasFzam** 等服务发布完整的销售变更副本。它不是
Verifactu 税务队列；服务等待或网络中断不会阻止 TPV 收款。

可能显示以下事件类型：

| 事件 | 含义 |
|------|------|
| `VENTA_CONFIRMADA` | 新建或确认销售。 |
| `VENTA_ANULADA` | 作废销售。 |
| `VENTA_SUSTITUIDA` | 由另一张单据替代。 |
| `VENTA_REABIERTA` | 受控重新打开销售。 |
| `FISCAL_ACTUALIZADO` | 后续更改税务信息。 |
| `TICKET_PDF_ACTUALIZADO` | 添加或更新票据 PDF。 |
| `FACTURA_PDF_ACTUALIZADO` | 添加或更新发票 PDF。 |

列表显示事件、公司、系列和编号、类型、状态、尝试次数、下次尝试时间、
发送日期、请求标识符和最后一次错误。状态包括：

| 状态 | 含义 |
|------|------|
| **PENDIENTE** | 等待下一个周期或下次尝试日期。 |
| **PROCESANDO** | 某个应用程序进程已占用该事件，准备发送。 |
| **ENVIADA** | 服务已接受该事件并返回成功结果。 |
| **ERROR** | 已用尽配置的最大尝试次数。 |

选择一行后，下方面板会显示其全部 HTTP 尝试：方法、资源、HTTP 状态、
结果、持续时间和请求标识符。**Petición**、**Respuesta del servidor** 和
**Error** 标签页显示已记录内容；历史记录会省略凭据和敏感二进制内容。

- **Actualizar** 重新加载队列及其历史记录，但不会强制发送。
- **Ir a Documento** 打开关联的发票或简化草稿。

该窗口为**只读**：不能插入、修改、删除或重试行。
`VentasWsCola.consultar`、`VentasWsCola.excel` 和
`VentasWsCola.detalle` 权限分别控制访问、导出和请求/响应视图。管理员可以
查看所有公司；其他用户只能查看其会话中的公司。没有有效公司时，查询不会
返回任何行。

#### 队列周期、重试与恢复

默认情况下，进程每 **60 秒**检查一次队列（`appVentasWsSegundosCiclo`；
最短 5 秒），最多尝试 **20 次**（`appVentasWsMaxIntentos`）。失败后，行会
保留为 `PENDIENTE`，并依次等待 1、2、4、8、16、32 和 64 分钟；后续尝试的
最长等待时间为 64 分钟。达到上限后，状态变为 `ERROR`。

如果应用程序中断时某一行处于 `PROCESANDO`，并且该行锁定超过十分钟，
系统会将其恢复为 `PENDIENTE`。修复网络或配置问题后，仍处于 `PENDIENTE`
的行会在下次尝试时自动继续。已经耗尽次数并进入 `ERROR` 的行不能从此窗口
重新入队，必须由管理员或支持人员检查。

#### 必要配置

在 **Otros ▸ Parámetros del entorno ▸ Servicios web** 中，以下参数必须有值：

- `appApiUrl`：Web 服务通用 URL。
- `appApiToken`：安装的 API key 或令牌。
- `appApiReferencia`：安装的全局引用。

此外，还必须在 **TPV ▸ Parámetros de Caja ▸ Servicios web** 中启用
**Enviar ventas completas al webservice de respaldo**
（`vgerEnviarVentasWS`）。其初始值为 `False`；禁用时不会创建新事件。
已经入队的事件仍会继续执行，直至完成或用尽尝试次数。移动应用的启用步骤
请参阅 [VentasFzam](13-aplicaciones-moviles.md#puesta-en-marcha-administrador)。

---

## Hacer Copia de Seguridad

![Diálogo de copia de seguridad](img/07-copia-seguridad.png)

**菜单快捷键：** `[Ctrl]+[Y]`

启动数据库**备份**，生成包含客户、商品、单据、库存等业务数据的备份文件。
对于 `fza_traducciones`，只会包含通过可下载软件包安装的语言。已编译的
西班牙语和工作目录不会重复备份；如果使用 `utlTraduc` 维护自己的语言，
还应单独保留其 SQL 或管理导出文件。

> 请**定期**备份，并将备份存放在安全且独立于本机的位置。发生磁盘故障或
> 意外删除时，备份是唯一的安全保障。

---

## Recuperar Copia de Seguridad

**菜单快捷键：** `[Ctrl]+[Z]`

可以从备份文件**恢复**数据库，或对数据库**执行维护脚本**。

> ⚠️ **谨慎操作。**恢复备份会**覆盖当前数据**。请确认选择了正确文件，
> 并确保没有其他人正在操作。如有疑问，请先备份当前状态。

---

## Generador de Procesos

![Generador de Procesos con la pestaña Código SQL](img/07-generador-procesos.png)

**菜单快捷键：** `[Ctrl]+[G]`

面向管理员的**高级**工具，可编写、保存并对数据库执行 **SQL 流程**：既可以
制作菜单中没有的**自定义报表**，也可以**批量修正**数据或调用存储过程。

每个流程都保存为一条记录（包含 **Código** 和 **Nombre de proceso**），
因此常用报表可以形成一个**可复用库**：在 Lista 中找到、打开并再次执行。

### 界面标签页

| 标签页 | 内容 |
|--------|------|
| **1_Código SQL** | 带语法高亮的 SQL 编辑器，用于编写流程。**Bonito** 按钮可重新格式化并缩进语句。 |
| **2_Metadatos** | 包含数据库对象（表、视图和过程）的树，可在编写时作为参考；其子标签页为 **Estructura Metadato**（对象 DDL）和 **Vista Contenido**（对象数据）。 |
| **3_VistaDatos** | 显示上一次执行**结果**的数据网格。 |
| **4_Otros** | 流程审计信息（由谁、何时创建或修改）。 |

**主要按钮：** **Ejecutar (F5)** 和 **Script (F3)**。后者将磁盘上的
`.sql`/`.txt` 文件加载为新流程，并以文件名作为流程名称。编辑器的上下文
菜单还提供 *Seleccionar Todo*、*Ejecutar*、*Comentar* 和 *Abrir Script*。

### 生成报表

1. 按 **Insertar registro**，为流程填写 **Código** 和 **Nombre**
   （例如 `L001 — Ventas por familia`）。
2. 在 **1_Código SQL** 中编写 `SELECT …` 查询。可使用以下辅助功能：
   - **2_Metadatos** 中的树显示所有表和视图；**双击**表/视图可在
     *Vista Contenido* 中查看内容；焦点位于树上时，按 **`[Ctrl]+[A]`**
     可将对象结构发送到编辑器。
   - **Bonito** 可重新格式化 SQL，使其更易阅读。
3. 按 **Ejecutar (F5)**：
   - 如果编辑器中有**选中文本**，则只执行所选部分；否则执行全部内容。
   - 结果会在 **3_VistaDatos** 中打开，结果面板同时显示记录数和执行时间。
4. 在数据网格中处理结果（排序、分组、筛选），然后使用 **Exp. Excel**
   （导出到 Excel）或 **Copiar Datos**（复制到剪贴板）输出。
5. 按 **Grabar** 保存流程，以便以后再次生成该报表。

![Resultado de un listado en VistaDatos](img/07-generador-listado.png)

> **Editar Grid** 按钮允许直接在数据库中编辑结果。它适合少量修正，
> 但会**修改真实数据**：使用时应像执行 UPDATE 一样谨慎。

### 执行流程（命令和存储过程）

- **命令**（`UPDATE`、`INSERT`、`DELETE` 等）：按相同方式编写，并通过
  **Ejecutar (F5)** 执行。结果面板不会显示数据网格，而是显示**受影响行数**
  和执行时间。
- **存储过程**：在 **2_Metadatos** 树中**双击**过程，应用程序会在编辑器中
  生成 `CALL procedimiento(…)` 模板，并将其**参数以注释形式列出**（各参数的
  名称和类型）。将注释替换为实际值，然后按 **Ejecutar (F5)**。如果过程
  返回行，则显示在 **VistaDatos** 中；否则按命令报告。
- **同时执行多条语句**：如果编辑器包含多条以 `;` 分隔的语句，每条语句会在
  **自己的结果标签页**中执行（每个查询一个数据网格，每个命令一条受影响行
  记录）。
- **分段执行**：选择某条具体语句并按 F5，只执行**该部分**。这是逐步测试
  长流程最安全的方式。

> 本功能面向技术用户。写错的语句可能修改或删除数据：**执行批量流程前请先
> 备份**；先使用 `SELECT` 查看将受影响的行，并优先执行选中部分，而不是
> 整个脚本。

---

## Procesos auxiliares BBDD

**路径：** *Otros ▸ Procesos auxiliares BBDD*

用于检查数据库元数据的技术工具。当前列表显示目录中的表，并可查看其
**Estructura SQL** 和内容；双击可打开当前表的记录。

| 操作 | 结果 |
|------|------|
| **Refrescar metadatos** | 重新读取当前数据库目录。 |
| **Ver contenido** | 在数据网格中打开所选表的记录。 |
| **Copiar SQL** | 将显示的 SQL 结构复制到剪贴板。 |
| **Exportar a Excel** | 导出已打开的内容。 |
| **Editar datos / Bloquear edición** | 启用直接编辑数据网格，或再次将其锁定。 |

> 此选项仅供获授权的技术用户使用。**Editar datos** 会直接操作真实数据库，
> 也允许新增和删除记录；请先备份，不要将其用于日常工作。

---

[◀ Almacén 菜单](06-menu-almacen.md) · [目录](README.md) · [下一章 ▶ Ayuda 菜单](08-menu-ayuda.md)
