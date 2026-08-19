# 12 · 更改与新增功能

[◀ 返回目录](README.md)

本章将**近期新增功能**与已经纳入常规手册的功能分开说明。要学习日常使用，
请始终进入相应的菜单章节；本页只是更改内容的快速索引。

> **文档审订日期：** 2026 年 8 月 19 日。某项功能列在此索引中，并不能替代
> 对已安装版本及其生产环境验证状态的检查。

---

## 近期新增功能

| 新增功能 | 参阅位置 |
|----------|----------|
| 手动导入 **PrestaShop** 订单，可受控新建客户和商品，并将运费记录为 `GASTOS_T` 服务，使用标准增值税且不产生库存移动。此功能仍仅限实验环境和单一受控目标使用。 | [Ventas Mayor ▸ Pedidos](04-menu-ventas-mayor.md#importar-pedidos-de-prestashop) · [PrestaShop 集成](15-integracion-prestashop.md) |
| 集中的 **Otros ▸ Colas de envíos** 菜单，可从实际菜单路径监控 Verifactu、PrestaShop 和 Web Service Fzam。 | [Otros ▸ Colas de envíos](07-menu-otros.md#colas-de-envios) |
| **Web Service Fzam** 队列，包含销售及 PDF 事件、状态、HTTP 历史记录、指数退避重试，并可访问关联单据。 | [Otros ▸ Colas de envíos ▸ Web Service Fzam](07-menu-otros.md#web-service-fzam) |
| **Histórico de Solicitudes de Traspaso**，包含已满足/未满足数量、原因、调拨及相关库存移动。 | [TPV ▸ Histórico de Solicitudes de Traspaso](05-menu-caja.md#historico-de-solicitudes-de-traspaso) |
| 按期间生成 **Facturas proforma**：针对 VE 销售的内部非税务形式发票，或针对 TA 调拨的 Ventas Mayor 草稿。 | [TPV ▸ Facturas proforma](05-menu-caja.md#facturas-proforma) |
| 使用 **Procesos auxiliares BBDD** 检查表的 SQL 结构和内容。 | [Otros ▸ Procesos auxiliares BBDD](07-menu-otros.md#procesos-auxiliares-bbdd) |
| `[F1]` 可在 Auto/desglose、SKU 和各尺码模式之间切换行显示；循环方式会适配每种单据类型。 | [通用概念 ▸ 使用 F1 的行模式](01-conceptos-comunes.md#cambiar-la-presentacion-de-las-lineas-con-f1) |
| 采购订单支持按行或尺码部分收货、**Recibir Todo**、Pedido/A recibir/Pendiente 分带，并可加入现有送货单。 | [Compras ▸ Pedidos](03-menu-compras.md#pedidos) |
| 使用 `[Ctrl]+[U]` 打开 **Consulta de stocks de Factuzam**：按颜色、尺码和仓库查看现有量与待处理量、细分状态和关联照片，并可发送到 Documentos de Trabajo。 | [Ayuda ▸ Consulta de stocks](08-menu-ayuda.md#consulta-de-stocks) |
| Android 应用 **Factuzam Fotos Nube**，可按商品/颜色拍照、加入队列并分批上传到服务器。 | [移动应用 ▸ Fotos Nube](13-aplicaciones-moviles.md#factuzam-fotos-nube-fotografiar-articulos-desde-android) |
| **提交给支持团队的错误管理**：受保护的证据、对话、按用户跟踪，以及经过验证的脚本或更新建议。 | [Ayuda ▸ Envío de errores](08-menu-ayuda.md#envio-de-errores-administracion-y-seguimiento) |
| 界面可通过中央目录翻译，提供可下载的 `en-GB`、`ca-ES` 和 `zh-CN` 软件包、西班牙语后备文本及独立翻译编辑器。 | [Otros ▸ Parámetros del entorno ▸ Apariencia ▸ Idioma](07-menu-otros.md#idioma-y-traducciones) |
| 票据可按**差额**更正，或通过**替代**单据更正，同时保留税务可追溯性，并一致处理销售和库存。 | [TPV ▸ Rectificar un ticket](05-menu-caja.md#rectificar-un-ticket-por-diferencias-o-sustitutiva) |
| 采购会话支持**临时照片**和预览，并可自动将图片迁移到最终创建的商品或 SKU。 | [Compras ▸ Fotos de la sesión](03-menu-compras.md#7-fotos-de-la-sesion) |
| 移动应用 **VentasFzam**，可查看当日销售、照片、成本、毛利和折扣，而不修改数据。 | [移动应用 ▸ VentasFzam](13-aplicaciones-moviles.md#ventasfzam-ventas-del-dia-en-el-movil) |
| 分层架构、逐步应用 SOLID，以及可审查、可配置并带验证和后备机制的 SQL 查询目录。 | [架构与开发](14-arquitectura-y-desarrollo.md) |
| 按日期查询 **Listado de operaciones de venta del TPV**，显示基础颜色；用户不受限制时，可累计选择公司、仓库和收银机。 | [TPV ▸ Listados](05-menu-caja.md#listados) |
| **Documentos de Trabajo**：可共享的商品/SKU 列表，用于打印标签，并可发送到送货单、TPV、盘点或价目表变更。 | [Almacén ▸ Documentos de Trabajo](06-menu-almacen.md#documentos-de-trabajo) |
| 可从任意窗口按 `[Ctrl]+[E]` 使用 **Búsqueda de datos de artículos**：按尺码、颜色、调色板相近程度、库存和已保存配置文件搜索。 | [通用概念 ▸ Búsqueda de datos](01-conceptos-comunes.md#busqueda-de-datos-de-articulos-ctrle) |
| **TPV 客户账户**（F2）：充值预存款和账户余额、通过正负号取消，以及在预存款之间分配部分收款。 | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| **付款票据报表**，可按到期日、供应商、银行/批次、类型和状态筛选。 | [Compras ▸ Listados](03-menu-compras.md#listados-listado-de-efectos-de-pago) |
| **Ayuda** 菜单可直接访问**在线手册**和**支持论坛**。 | [Ayuda 菜单](08-menu-ayuda.md) |
| 从已合并的 Ventas Mayor 销售草稿签发带签名的 Facturae eDoc。 | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#efectos-y-edoc-en-el-borrador) |
| 客户 eDoc 参数：DIR3 和自然人数据。 | [Clientes](02-menu-archivo.md#clientes) |
| 在支付方式中设置 Facturae 代码，以申报官方支付手段。 | [Formas de pago documentos](07-menu-otros.md#formas-de-pago-documentos) |
| 客户应收票据及到期款项核销。 | [Efectos de cobro](04-menu-ventas-mayor.md#efectos-de-cobro) |
| 收款批次、加载票据和生成 SEPA。 | [Remesas de cobro](04-menu-ventas-mayor.md#remesas-de-cobro) |
| 从送货单创建采购发票/草稿，并可加入现有单据。 | [Compras ▸ Crear borradores de albaranes](03-menu-compras.md#crear-borradores-de-albaranes) |
| 完整采购迁移：订单、送货单、退货、发票、票据和批次。 | [从旧系统迁移](10-migracion-legacy.md#2-que-datos-migra) |

---

## 已纳入常规手册

以下功能不再作为刚刚新增的内容处理；它们已按业务领域分类，并在手册的
常规章节中说明。

### Archivo 与商品目录

| 已纳入功能 | 参阅位置 |
|------------|----------|
| 按公司维护银行账户，并标记默认收款和付款账户。 | [Empresas](02-menu-archivo.md#empresas) |
| 客户的默认收款银行。 | [Clientes](02-menu-archivo.md#clientes) |
| 供应商的默认支付方式和付款银行。 | [Proveedores](02-menu-archivo.md#proveedores) |
| 采购会话所用的按尺码数量套装。 | [Proveedores ▸ Compras](02-menu-archivo.md#pestana-compras-parametros-de-compra-del-proveedor) |
| 按商品、颜色或 SKU 管理照片，带浮动窗口并可从服务器下载。 | [通用概念 ▸ 浮动照片](01-conceptos-comunes.md#foto-flotante-del-articulo-sku) |
| 每种计量单位可使用小数数量。 | [Unidades de Medida](02-menu-archivo.md#unidades-de-medida) |
| 基本属性和标准颜色/尺码对应关系。 | [Atributos básicos](02-menu-archivo.md#atributos-basicos) |
| 价目表变更会话及折扣日期窗口。 | [Tarifas](02-menu-archivo.md#tarifas) |

### Compras

| 已纳入功能 | 参阅位置 |
|------------|----------|
| 采购会话支持应用套装并提供供应商标签页。 | [Sesiones de compra](03-menu-compras.md#sesiones-crear-articulos-y-un-pedido-o-un-albaran) |
| 采购送货单中的信息标记 **Depósito**。 | [Albaranes de compra](03-menu-compras.md#albaranes) |
| 供应商退货作为独立单据处理，并产生库存出库。 | [Devoluciones a Proveedor](03-menu-compras.md#devoluciones-a-proveedor) |
| 采购草稿可生成票据。 | [Borradores](03-menu-compras.md#borradores) |
| 供应商付款票据和付款批次。 | [Efectos de pago](03-menu-compras.md#efectos-de-pago) |

### 销售与 Caja

| 已纳入功能 | 参阅位置 |
|------------|----------|
| 税务结算前使用 **Borradores** 术语。 | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#borradores) |
| 按日期范围从销售送货单创建销售草稿。 | [Albaranes de venta](04-menu-ventas-mayor.md#albaranes) |
| 简化收银草稿，并可转换为普通草稿。 | [TPV ▸ Borradores Simplificados](05-menu-caja.md#borradores-simplificados) |
| TPV 行中显示照片、颜色/尺码和 SKU 数据。 | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| 完整扩展收银流程：营业日、票据、代金券、借款、调拨、盘点和收银流水。 | [TPV](05-menu-caja.md) |
| 说明全部 Caja 参数及其当前实际效果。 | [TPV ▸ Parámetros de Caja](05-menu-caja.md#parametros-de-caja) |
| 从 TPV 查看现金盘点历史，并可补打票据/结算单。 | [TPV ▸ Arqueo](05-menu-caja.md#arqueo-f11) |
| A4 现金盘点历史报表。 | [TPV ▸ Histórico de Arqueos](05-menu-caja.md#historico-de-arqueos) |

### Almacén 与报表

| 已纳入功能 | 参阅位置 |
|------------|----------|
| 通过 Android 应用和桥接服务器执行移动盘点。 | [Inventarios ▸ Recuento móvil](06-menu-almacen.md#recuento-movil) |
| 按尺码横向显示仓库结余，支持照片、筛选、分带和分组。 | [Balance de Almacén Horizontal](06-menu-almacen.md#balance-de-almacen-horizontal) |
| 对整个商品目录显示不分尺码的仓库结余。 | [Balance de Almacén sin tallas](06-menu-almacen.md#balance-de-almacen-sin-tallas) |
| 按商品和日期查看销售移动及毛利。 | [Movimientos de ventas por artículos y fechas](06-menu-almacen.md#movimientos-de-ventas-por-articulos-y-fechas) |
| 报表中使用树形商品分类筛选器。 | [Informes de almacén](06-menu-almacen.md#informes) |

### 管理与税务

| 已纳入功能 | 参阅位置 |
|------------|----------|
| 集中管理 Fotos、Recuentos 和 Verifactu 参数。 | [Parámetros del entorno](07-menu-otros.md#parametros-del-entorno) |
| 按菜单和界面操作管理树形权限。 | [Permisos](07-menu-otros.md#permisos) |
| 将员工与用户分开，用于收银、调拨和现金盘点。 | [Empleados](07-menu-otros.md#empleados) |
| 税务模式 `SIN`、`VERIFACTU` 和 `NO_VERIFACTU`。 | [Verifactu ▸ Configuración](11-verifactu.md#2-configuracion-previa-administrador) |
| 导出 NO VERI*FACTU 记录的 XML。 | [Verifactu Log](11-verifactu.md#verifactu-log) |
| 针对欧盟内部交易、反向征税和出口设置 Verifactu 交易类型。 | [Verifactu en la ficha](11-verifactu.md#4-verifactu-en-la-ficha-de-la-factura) |

---

[◀ Verifactu](11-verifactu.md) · [目录](README.md) · [下一章 ▶ 移动应用](13-aplicaciones-moviles.md)
