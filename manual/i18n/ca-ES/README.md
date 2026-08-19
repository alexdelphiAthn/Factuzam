# Manual d'usuari — Factuzam

Benvingut al manual d'usuari de **Factuzam**, l'aplicació de gestió
comercial, facturació i punt de venda (TPV) per al comerç de moda i al
detall (articles amb talles, colors i atributs).

Aquest manual està organitzat seguint la **barra de menú principal** de
l'aplicació. Cada capítol documenta un menú i, dins seu, cada opció
(element de menú) una per una: què fa, quan cal utilitzar-la i els camps o
passos més rellevants.

## Obtenir la demo

La demo es distribueix com un instal·lador versionat. Utilitza sempre
l'enllaç vigent facilitat per Factuzam o per l'instal·lador; no reutilitzis
l'URL d'una compilació anterior. Si el web no mostra una descàrrega activa,
demana el paquet actual al suport abans de continuar aquest capítol.

> **Pràctica en el programa DEMO:** en començar, entra amb l'usuari
> administrador de la demo, crea un usuari propi amb la seva contrasenya a
> [Otros ▸ Usuarios, Grupos y Perfiles](07-menu-otros.md#usuarios-grupos-y-perfiles),
> assigna'l al grup **Administradores** i torna a entrar des de
> *Archivo ▸ Invocar login* per treballar amb el teu propi usuari.

## Projecte i llicència

El codi font de Factuzam està disponible al
[repositori oficial de GitHub](https://github.com/alexdelphiAthn/Factuzam).
El codi original del projecte es distribueix sota la
[Mozilla Public License 2.0 (MPL-2.0)](https://www.mozilla.org/MPL/2.0/),
amb les excepcions i condicions explicades al
[capítol d'Ajuda](08-menu-ayuda.md#proyecto-en-github-y-licencia).

---

## Índex

| Capítol | Contingut |
|---------|-----------|
| [00 · Accés i primers passos](00-acceso-y-primeros-pasos.md) | Inici, accés, configuració de la connexió a la base de dades i pantalla principal. |
| [01 · Conceptes comuns](01-conceptos-comunes.md) | Funcionament de les pantalles de manteniment: llista, fitxa, cerca, navegador, modes de línies amb `[F1]` i exportació. **Llegeix-lo abans que els altres.** |
| [02 · Menú Archivo](02-menu-archivo.md) | Dades mestres: Empreses, Magatzems, Clients, Proveïdors, Articles i Taules auxiliars. |
| [03 · Menú Compras](03-menu-compras.md) | Sessions de compra, Comandes, Albarans, Devolucions a proveïdor i Factures de compra. |
| [04 · Menú Ventas Mayor](04-menu-ventas-mayor.md) | Venda majorista: Esborranys, cartera de cobraments, Comandes, Albarans i Llistats de vendes. |
| [05 · Menú TPV](05-menu-caja.md) | Punt de venda: caixa, dipòsits, històrics, sol·licituds de traspàs, esborranys simplificats i factures proforma. |
| [06 · Menú Almacén](06-menu-almacen.md) | Moviments de magatzem, Inventaris, Documents de treball i Informes d'estoc. |
| [07 · Menú Otros](07-menu-otros.md) | Paràmetres, IVA, usuaris/permisos, cues d'enviaments, còpies de seguretat, Generador de processos i processos auxiliars de BBDD. |
| [08 · Menú Ayuda](08-menu-ayuda.md) | Consulta d'estocs, Manual web, GitHub, llicència i administració dels errors enviats al suport. |
| [09 · Instal·lació al Windows](09-instalacion-windows.md) | MariaDB, base de dades inicial, instal·lació per lloc de treball i posada en marxa. |
| [10 · Migració des de programari legacy](10-migracion-legacy.md) | Trasllat de dades de l'ERP anterior (SQL Server) amb Factuzam Migrator. |
| [11 · Verifactu (AEAT)](11-verifactu.md) | Sistema de facturació verificable: configuració, cua accessible des d'Otros, QR i accions fiscals (anul·lar, rectificar, esmenar). |
| [12 · Canvis i novetats](12-cambios-y-novedades.md) | Resum de les novetats recents i on es documenten dins del manual. |
| [13 · Aplicacions mòbils](13-aplicaciones-moviles.md) | Fotos d'articles, consulta de vendes diàries i recompte d'inventaris des d'Android. |
| [14 · Arquitectura i desenvolupament](14-arquitectura-y-desarrollo.md) | Estil de programació, principis SOLID, capes, proves i catàleg SQL configurable. |
| [15 · Integració amb PrestaShop](15-integracion-prestashop.md) | Configuració, catàleg i cua, importació de comandes, preus per SKU i estat de validació. |

---

## La barra de menú d'un cop d'ull

| Menú | Opcions principals |
|------|--------------------|
| **Archivo** | Empresas, Almacenes, Clientes, Proveedores, Artículos, Tablas Auxiliares, Invocar login i Salir. |
| **Compras** | Sesiones, Pedidos, Albaranes, Devoluciones, Crear borradores, Borradores, Efectos y Remesas de pago, Cargar efectos i Listados. |
| **Ventas Mayor** | Pedidos, Albaranes, Borradores, Efectos y Remesas de cobro, Cargar efectos i Listados. |
| **TPV** | Menú de Caja, Listados, Parámetros, Formas de pago, Depósitos, històrics de caixa, Histórico de Solicitudes de Traspaso, Borradores Simplificados i Facturas proforma. |
| **Almacén** | Movimientos, Inventarios, Documentos de Trabajo i Informes. |
| **Otros** | Parámetros del entorno, IVA, Contadores, Formas de pago documentos, Usuarios y Perfiles, **Colas de envíos** (Verifactu, PrestaShop i Web Service Fzam), Copias de Seguridad, Generador de Procesos i Procesos auxiliares BBDD. |
| **Verifactu** | Declaración Responsable i Verifactu Log. La cua és a **Otros ▸ Colas de envíos ▸ Verifactu**. |
| **Ayuda** | Consulta de stocks, Artículos similares, Manual web, Foro de soporte, Envío de errores i Acerca de. |

> **Nota:** les opcions visibles depenen del teu **perfil d'usuari i dels
> permisos** assignats. Si una opció apareix desactivada o no apareix,
> consulta-ho amb l'administrador (vegeu
> [Menú Otros → Usuarios, Grupos y Perfiles](07-menu-otros.md)).

---

## Convencions d'aquest manual

- **Negreta** per als noms de menús, botons i camps de pantalla.
- `Codi` per als noms tècnics (taules, fitxers, paràmetres).
- Les icones `▸` indiquen una ruta de menú, per exemple:
  *Archivo ▸ Tablas Auxiliares ▸ Tarifas*.
- Les tecles es mostren entre claudàtors, per exemple `[F12]`, `[Esc]` o
  `[Ctrl]+[A]`.
