# 12 · Canvis i novetats

[◀ Tornar a l'índex](README.md)

Aquest capítol separa les **novetats recents** de les funcions que ja
han quedat incorporades al manual normal. Per aprendre l'ús diari,
entra sempre al capítol de menú corresponent; aquesta pàgina només és
un mapa ràpid de canvis.

> **Revisió documental:** 19/08/2026. Que una funció figuri en aquest mapa no
> substitueix la comprovació de la versió instal·lada ni del seu estat de
> validació per a producció.

---

## Novetats recents

| Novetat | On veure-ho |
|---------|-------------|
| Importació manual de comandes de **PrestaShop**, amb alta controlada de clients i articles i ports com a servei `GASTOS_T` amb IVA normal i sense moviment d'estoc. El seu ús continua limitat al laboratori i a una única destinació controlada. | [Ventas Mayor ▸ Pedidos](04-menu-ventas-mayor.md#importar-pedidos-de-prestashop) · [Integració amb PrestaShop](15-integracion-prestashop.md) |
| Menú centralitzat **Otros ▸ Colas de envíos** per supervisar Verifactu, PrestaShop i Web Service Fzam des de la seva ruta real. | [Otros ▸ Colas de envíos](07-menu-otros.md#colas-de-envios) |
| Cua de **Web Service Fzam** amb esdeveniments de venda i PDF, estats, historial HTTP, reintents exponencials i accés al document associat. | [Otros ▸ Colas de envíos ▸ Web Service Fzam](07-menu-otros.md#web-service-fzam) |
| **Histórico de Solicitudes de Traspaso** amb quantitats servides/no servides, motius, traspassos i moviments d'estoc relacionats. | [TPV ▸ Histórico de Solicitudes de Traspaso](05-menu-caja.md#historico-de-solicitudes-de-traspaso) |
| **Facturas proforma** per període: proforma interna no fiscal de vendes VE o esborranys de Venta Mayor per a traspassos TA. | [TPV ▸ Facturas proforma](05-menu-caja.md#facturas-proforma) |
| **Procesos auxiliares BBDD** per inspeccionar l'estructura SQL i el contingut de les taules. | [Otros ▸ Procesos auxiliares BBDD](07-menu-otros.md#procesos-auxiliares-bbdd) |
| `[F1]` canvia la presentació de línies entre Auto/desglose, SKU i els modes de talles; el cicle s'adapta a cada tipus de document. | [Conceptes comuns ▸ Modes de línies amb F1](01-conceptos-comunes.md#cambiar-la-presentacion-de-las-lineas-con-f1) |
| Comandes de compra amb recepció parcial per línia o talla, **Recibir Todo**, bandes Pedido/A recibir/Pendiente i incorporació a un albarà existent. | [Compras ▸ Pedidos](03-menu-compras.md#pedidos) |
| **Consulta de stocks de Factuzam** amb `[Ctrl]+[U]`: existències i pendents per color, talla i magatzem, estats desglossats, fotos relacionades i enviament a Documentos de Trabajo. | [Ayuda ▸ Consulta de stocks](08-menu-ayuda.md#consulta-de-stocks) |
| Aplicació Android **Factuzam Fotos Nube** per capturar fotos per article/color, posar-les en cua i pujar-les per lots al servidor. | [Aplicacions mòbils ▸ Fotos Nube](13-aplicaciones-moviles.md#factuzam-fotos-nube-fotografiar-articulos-desde-android) |
| **Administració d'errors enviats al suport**: evidències protegides, conversa, seguiment per usuari i propostes verificades de script o actualització. | [Ayuda ▸ Envío de errores](08-menu-ayuda.md#envio-de-errores-administracion-y-seguimiento) |
| Interfície traduïble des d'un catàleg central, paquets descarregables `en-GB`, `ca-ES` i `zh-CN`, alternativa en espanyol i editor independent de traduccions. | [Otros ▸ Parámetros del entorno ▸ Apariencia ▸ Idioma](07-menu-otros.md#idioma-y-traducciones) |
| Rectificació de tiquets **per diferències** o mitjançant document **substitutiu**, amb traçabilitat fiscal i tractament coherent de vendes i estoc. | [TPV ▸ Rectificar un ticket](05-menu-caja.md#rectificar-un-ticket-por-diferencias-o-sustitutiva) |
| Sessions de compra amb **foto provisional**, vista prèvia i migració automàtica de la imatge a l'article o SKU materialitzat. | [Compras ▸ Fotos de la sesión](03-menu-compras.md#7-fotos-de-la-sesion) |
| Aplicació mòbil **VentasFzam** per consultar vendes del dia, fotografies, cost, marge i descomptes sense modificar dades. | [Aplicacions mòbils ▸ VentasFzam](13-aplicaciones-moviles.md#ventasfzam-ventas-del-dia-en-el-movil) |
| Arquitectura per capes, aplicació progressiva de SOLID i catàleg de consultes SQL revisables i configurables amb validació i fallback. | [Arquitectura i desenvolupament](14-arquitectura-y-desarrollo.md) |
| **Listado de operaciones de venta del TPV** per dates, amb color bàsic visual i selecció acumulativa d'empreses/magatzems/caixes quan l'usuari no està restringit. | [TPV ▸ Listados](05-menu-caja.md#listados) |
| **Documentos de Trabajo**: llistes d'articles/SKUs per compartir, imprimir etiquetes i enviar a albarà, TPV, inventari o canvi de tarifes. | [Almacén ▸ Documentos de Trabajo](06-menu-almacen.md#documentos-de-trabajo) |
| **Búsqueda de datos de artículos** amb `[Ctrl]+[E]` des de qualsevol finestra: per talla, color, proximitat de paleta, estoc i perfils desats. | [Conceptes comuns ▸ Búsqueda de datos de artículos](01-conceptos-comunes.md#busqueda-de-datos-de-articulos-ctrle) |
| **Compte de client al TPV** (F2): càrrega de dipòsits i abonaments a compte, cancel·lació per signe i repartiment del cobrament parcial en dipòsits. | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| **Llistat d'efectes de pagament** amb filtres per venciment, proveïdor, banc/remesa, tipus i situació. | [Compras ▸ Listados](03-menu-compras.md#listados-listado-de-efectos-de-pago) |
| Menú **Ayuda** amb accés directe al **manual web** i al **foro de soporte**. | [Menú Ayuda](08-menu-ayuda.md) |
| Emissió d'eDoc Facturae signat des d'esborranys de venda major consolidats. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#efectos-y-edoc-en-el-borrador) |
| Paràmetres eDoc del client: DIR3 i dades de persona física. | [Clientes](02-menu-archivo.md#clientes) |
| Codi Facturae en formes de pagament per informar el mitjà de pagament oficial. | [Formas de pago documentos](07-menu-otros.md#formas-de-pago-documentos) |
| Efectes de cobrament a client i conciliació de venciments. | [Efectos de cobro](04-menu-ventas-mayor.md#efectos-de-cobro) |
| Remeses de cobrament, càrrega d'efectes i generació SEPA. | [Remesas de cobro](04-menu-ventas-mayor.md#remesas-de-cobro) |
| Factures/esborranys de compra creats des d'albarans i que es poden incorporar a un document existent. | [Compras ▸ Crear borradores de albaranes](03-menu-compras.md#crear-borradores-de-albaranes) |
| Migració de compres completa: comandes, albarans, devolucions, factures, efectes i remeses. | [Migració des de legacy](10-migracion-legacy.md#2-que-datos-migra) |

---

## Incorporat al manual

Les funcions següents ja no es tracten com a acabades d'afegir; queden
classificades per la seva àrea de treball i documentades als capítols
normals del manual.

### Archivo i catàleg

| Funció incorporada | On veure-ho |
|---------------------|-------------|
| Comptes bancaris per empresa, amb marques de cobrament i pagament per defecte. | [Empresas](02-menu-archivo.md#empresas) |
| Banc de cobrament per defecte en clients. | [Clientes](02-menu-archivo.md#clientes) |
| Forma de pagament i banc de pagament per defecte en proveïdors. | [Proveedores](02-menu-archivo.md#proveedores) |
| Kits de quantitats per talla per a sessions de compra. | [Proveedores ▸ Compras](02-menu-archivo.md#pestana-compras-parametros-de-compra-del-proveedor) |
| Fotos per article, color o SKU, amb finestra flotant i descàrrega des del servidor. | [Conceptes comuns ▸ Foto flotant](01-conceptos-comunes.md#foto-flotante-del-articulo-sku) |
| Unitats de mesura amb decimals per unitat. | [Unidades de Medida](02-menu-archivo.md#unidades-de-medida) |
| Atributs bàsics i equivalències estàndard de color/talla. | [Atributos básicos](02-menu-archivo.md#atributos-basicos) |
| Sessions de canvis de tarifa i finestra de dates per a descomptes. | [Tarifas](02-menu-archivo.md#tarifas) |

### Compras

| Funció incorporada | On veure-ho |
|---------------------|-------------|
| Sessions de compra amb aplicació de kits i pestanya de proveïdor. | [Sesiones de compra](03-menu-compras.md#sesiones-crear-articulos-y-un-pedido-o-un-albaran) |
| Marca informativa **Depósito** en albarans de compra. | [Albaranes de compra](03-menu-compras.md#albaranes) |
| Devolucions a proveïdor com a document propi amb sortida d'estoc. | [Devoluciones a Proveedor](03-menu-compras.md#devoluciones-a-proveedor) |
| Esborranys de compra amb generació d'efectes. | [Borradores](03-menu-compras.md#borradores) |
| Efectes i remeses de pagament a proveïdor. | [Efectos de pago](03-menu-compras.md#efectos-de-pago) |

### Vendes i Caja

| Funció incorporada | On veure-ho |
|---------------------|-------------|
| Terminologia de **Borradores** abans del tancament fiscal. | [Ventas Mayor ▸ Borradores](04-menu-ventas-mayor.md#borradores) |
| Crear esborranys de venda des d'albarans per interval de dates. | [Albaranes de venta](04-menu-ventas-mayor.md#albaranes) |
| Esborranys simplificats de caixa i conversió a esborrany normal. | [TPV ▸ Borradores Simplificados](05-menu-caja.md#borradores-simplificados) |
| TPV amb foto, color/talla i dades de SKU en línies. | [TPV ▸ Ventas](05-menu-caja.md#ventas-f5-la-pantalla-de-venta) |
| Ampliació completa del flux de caixa: jornada, tiquets, vals, préstecs, traspassos, recompte i tira de caixa. | [TPV](05-menu-caja.md) |
| Detall de tots els paràmetres de Caja i del seu efecte operatiu actual. | [TPV ▸ Parámetros de Caja](05-menu-caja.md#parametros-de-caja) |
| Històric d'arqueigs des del TPV amb duplicat de tiquet/tancament. | [TPV ▸ Arqueo](05-menu-caja.md#arqueo-f11) |
| Informe A4 de l'històric d'arqueigs. | [TPV ▸ Histórico de Arqueos](05-menu-caja.md#historico-de-arqueos) |

### Almacén i informes

| Funció incorporada | On veure-ho |
|---------------------|-------------|
| Recompte mòbil d'inventaris mitjançant app Android i servidor pont. | [Inventarios ▸ Recuento móvil](06-menu-almacen.md#recuento-movil) |
| Balanç de magatzem horitzontal per talles, amb fotos, filtres, bandes i agrupacions. | [Balance de Almacén Horizontal](06-menu-almacen.md#balance-de-almacen-horizontal) |
| Balanç de magatzem sense talles per a tot el catàleg. | [Balance de Almacén sin tallas](06-menu-almacen.md#balance-de-almacen-sin-tallas) |
| Moviments de vendes per articles i dates, amb marges. | [Movimientos de ventas por artículos y fechas](06-menu-almacen.md#movimientos-de-ventas-por-articulos-y-fechas) |
| Filtre de famílies com a arbre als informes. | [Informes de almacén](06-menu-almacen.md#informes) |

### Administració i fiscalitat

| Funció incorporada | On veure-ho |
|---------------------|-------------|
| Paràmetres de Fotos, Recuentos i Verifactu centralitzats. | [Parámetros del entorno](07-menu-otros.md#parametros-del-entorno) |
| Permisos en arbre, per menú i per acció de pantalla. | [Permisos](07-menu-otros.md#permisos) |
| Empleats separats dels usuaris per a caixa, traspassos i arqueigs. | [Empleados](07-menu-otros.md#empleados) |
| Modes fiscals `SIN`, `VERIFACTU` i `NO_VERIFACTU`. | [Verifactu ▸ Configuración](11-verifactu.md#2-configuracion-previa-administrador) |
| Exportació XML de registres NO VERI*FACTU. | [Verifactu Log](11-verifactu.md#verifactu-log) |
| Tipus d'operació Verifactu per a intracomunitàries, inversió del subjecte passiu i exportacions. | [Verifactu en la ficha](11-verifactu.md#4-verifactu-en-la-ficha-de-la-factura) |

---

[◀ Verifactu](11-verifactu.md) · [Índex](README.md) · [Següent ▶ Aplicacions mòbils](13-aplicaciones-moviles.md)
