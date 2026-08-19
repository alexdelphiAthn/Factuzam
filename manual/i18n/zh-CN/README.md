# Factuzam 用户手册

欢迎阅读 **Factuzam** 用户手册。Factuzam 是一套面向时装及零售行业的
商业管理、开票和销售点（TPV）应用程序，可管理带尺码、颜色和属性的
商品。

本手册按照应用程序的**主菜单栏**编排。每章对应一个菜单，并逐项说明
其中的菜单命令：它的作用、适用场景，以及最重要的字段和操作步骤。

## 获取演示版

演示版以带版本号的安装程序发布。请始终使用 Factuzam 或安装程序提供的
当前有效链接，不要重复使用旧版本的 URL。如果网站没有显示可用下载，
请先向支持人员索取当前安装包，再继续本章。

> **在 DEMO 程序中练习：**首次使用时，请以演示版管理员账户登录，
> 在 [Otros ▸ Usuarios, Grupos y Perfiles](07-menu-otros.md#usuarios-grupos-y-perfiles)
> 中创建自己的用户和密码，将其分配到 **Administradores** 组，然后通过
> *Archivo ▸ Invocar login* 重新登录，以后使用自己的账户操作。

## 项目与许可证

Factuzam 的源代码托管在
[GitHub 官方仓库](https://github.com/alexdelphiAthn/Factuzam)。
项目原始代码采用
[Mozilla Public License 2.0（MPL-2.0）](https://www.mozilla.org/MPL/2.0/)
发布；相关例外和条件请参阅
[帮助章节](08-menu-ayuda.md#proyecto-en-github-y-licencia)。

---

## 目录

| 章节 | 内容 |
|------|------|
| [00 · 访问与入门](00-acceso-y-primeros-pasos.md) | 启动、登录、数据库连接配置和主界面。 |
| [01 · 通用概念](01-conceptos-comunes.md) | 维护界面的工作方式：列表、详情、搜索、导航器、使用 `[F1]` 切换行显示模式以及导出。**建议先阅读本章。** |
| [02 · Archivo 菜单](02-menu-archivo.md) | 主数据：公司、仓库、客户、供应商、商品和辅助表。 |
| [03 · Compras 菜单](03-menu-compras.md) | 采购会话、订单、送货单、供应商退货和采购发票。 |
| [04 · Ventas Mayor 菜单](04-menu-ventas-mayor.md) | 批发销售：草稿、应收款、订单、送货单和销售报表。 |
| [05 · TPV 菜单](05-menu-caja.md) | 销售点：收银、预存款、历史记录、调拨申请、简化草稿和形式发票。 |
| [06 · Almacén 菜单](06-menu-almacen.md) | 库存移动、盘点、工作文档和库存报表。 |
| [07 · Otros 菜单](07-menu-otros.md) | 参数、增值税、用户/权限、发送队列、备份、流程生成器和数据库辅助流程。 |
| [08 · Ayuda 菜单](08-menu-ayuda.md) | 库存查询、在线手册、GitHub、许可证，以及提交给支持团队的错误管理。 |
| [09 · Windows 安装](09-instalacion-windows.md) | MariaDB、初始数据库、每台工作站的安装和首次启用。 |
| [10 · 从旧系统迁移](10-migracion-legacy.md) | 使用 Factuzam Migrator 从旧 ERP（SQL Server）迁移数据。 |
| [11 · Verifactu（AEAT）](11-verifactu.md) | 可验证开票系统：配置、从 Otros 访问队列、二维码，以及作废、更正和补正等税务操作。 |
| [12 · 更改与新增功能](12-cambios-y-novedades.md) | 最近新增功能的摘要，以及它们在手册中的详细位置。 |
| [13 · 移动应用](13-aplicaciones-moviles.md) | 在 Android 上拍摄商品照片、查询每日销售和执行库存盘点。 |
| [14 · 架构与开发](14-arquitectura-y-desarrollo.md) | 编程风格、SOLID 原则、分层、测试和可配置 SQL 目录。 |
| [15 · PrestaShop 集成](15-integracion-prestashop.md) | 配置、目录和队列、订单导入、按 SKU 定价及验证状态。 |

---

## 主菜单速览

| 菜单 | 主要选项 |
|------|----------|
| **Archivo** | Empresas、Almacenes、Clientes、Proveedores、Artículos、Tablas Auxiliares、Invocar login 和 Salir。 |
| **Compras** | Sesiones、Pedidos、Albaranes、Devoluciones、Crear borradores、Borradores、Efectos y Remesas de pago、Cargar efectos 和 Listados。 |
| **Ventas Mayor** | Pedidos、Albaranes、Borradores、Efectos y Remesas de cobro、Cargar efectos 和 Listados。 |
| **TPV** | Menú de Caja、Listados、Parámetros、Formas de pago、Depósitos、收银历史、Histórico de Solicitudes de Traspaso、Borradores Simplificados 和 Facturas proforma。 |
| **Almacén** | Movimientos、Inventarios、Documentos de Trabajo 和 Informes。 |
| **Otros** | Parámetros del entorno、IVA、Contadores、Formas de pago documentos、Usuarios y Perfiles、**Colas de envíos**（Verifactu、PrestaShop 和 Web Service Fzam）、Copias de Seguridad、Generador de Procesos 和 Procesos auxiliares BBDD。 |
| **Verifactu** | Declaración Responsable 和 Verifactu Log。队列位于 **Otros ▸ Colas de envíos ▸ Verifactu**。 |
| **Ayuda** | Consulta de stocks、Artículos similares、Manual web、Foro de soporte、Envío de errores 和 Acerca de。 |

> **注意：**可见选项取决于你的**用户配置文件和已分配权限**。如果某项
> 显示为禁用或没有出现，请联系管理员（参阅
> [Menú Otros → Usuarios, Grupos y Perfiles](07-menu-otros.md)）。

---

## 本手册的排版约定

- 使用**粗体**表示菜单、按钮和界面字段的名称。
- 使用`代码格式`表示表、文件和参数等技术名称。
- `▸` 表示菜单路径，例如：*Archivo ▸ Tablas Auxiliares ▸ Tarifas*。
- 按键写在方括号中，例如 `[F12]`、`[Esc]` 和 `[Ctrl]+[A]`。
