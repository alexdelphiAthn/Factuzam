# 07 · Menú Otros

[◀ Tornar a l'índex](README.md)

El menú **Otros** agrupa l'**administració i configuració** de
l'aplicació: paràmetres de l'entorn, impostos, comptadors de numeració,
formes de pagament de documents, seguretat (usuaris i permisos),
còpies de seguretat i eines
avançades. Són opcions que utilitza principalment l'**administrador**.

Estructura del menú:

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

**Drecera de menú:** `[Ctrl]+[F10]`

Pantalla de **Parámetros Generales de la Aplicación**. Centralitza la
configuració de l'entorn: comportament per defecte, rutes, opcions
d'impressió i de documents, valors predeterminats de l'empresa de treball,
etc. Cada valor es pot assignar a un usuari, a un grup o a `Todos`.

Categories habituals:

| Categoria | Ús |
|-----------|----|
| **Directorios / Fotos** | Carpeta local o compartida de fotos (`appDirFotos`) i nombre d'atributs utilitzat a la seva clau. |
| **Servicios web** | URL (`appApiUrl`), credencial (`appApiToken`) i referència d'instal·lació (`appApiReferencia`) comunes per a fotos, correu, vendes, SIF i recomptes; també cicle i màxim d'intents de la cua de vendes. |
| **Verifactu** | Mode fiscal, entorn, dades del SIF, cicle de cua, URLs i paràmetres de signatura/rellotge. |
| **PrestaShop** | Connexió API, botiga, empresa, tarifa, cua, nivells de família i caselles **Sincronizar stock y precios**, **Crear artículos en PrestaShop al darlos de alta**, **Activar artículos en PrestaShop al marcar En web** i **Hacer barrido periódicamente**. |
| **Apariencia** | Tema, paleta de color i idioma de la interfície. |
| **Caja** | Valors per defecte del TPV i comportament d'arqueig. |

El valor efectiu es resol per herència: primer el valor propi de
l'**usuari**, després el del seu **grup** i, finalment, el de **Todos**. Un
valor més específic substitueix el més general. Això permet, per exemple,
que dos grups treballin amb empreses, magatzems i botigues PrestaShop
diferents. Cada sessió atén únicament la configuració efectiva del seu
usuari.

La clau API queda oculta per als usuaris que no són administradors arrel.
Les quatre caselles comencen desmarcades i són independents. **Sincronizar
stock y precios** autoritza l'actualització de productes existents
localitzats per una `reference` exacta i única. **Crear artículos en
PrestaShop al darlos de alta** sol·licita l'alta completa quan no existeix
aquesta correspondència. L'alta sempre crea primer el producte amb
`active=0`. **Activar artículos en PrestaShop al marcar En web**
(`appPrestaShopActivarArticulosAlMarcarWeb`) n'autoritza l'activació únicament
al final d'una alta o una sincronització correctes iniciades en passar **En
web** de No a Sí; el seu valor inicial és `False`. **Hacer barrido
periódicamente** habilita la reconciliació completa per hores; encara que
estigui desmarcada, la recuperació de pendents continua cada 60–120 segons.

**Niveles de familia a crear (0 = todos)**
(`appPrestaShopNivelesFamiliaAlta`) és un enter heretable amb valor inicial
`0`. Amb `0` s'exporta tota la jerarquia local; amb un valor positiu es
conserva aquest nombre de nivells comptats des de la família fulla i es creen
en ordre arrel → fulla. La categoria arrel configurada a PrestaShop no compta
com a nivell local. A **DEMO-CAMISA**, que té **ROPA** com a única família
local, només s'exporta aquest nivell amb qualsevol valor permès.

Abans d'activar la integració, segueix la
[llista de comprovació de la integració](15-integracion-prestashop.md#14-lista-de-comprobacion-para-una-implantacion).

### Idioma i traduccions

La selecció no és una opció independent del menú. La seva ruta exacta és
**Otros ▸ Parámetros del entorno ▸ Apariencia ▸ Idioma de la interfaz**.
El paràmetre `appIdioma` ofereix sempre espanyol (`es-ES`), anglès britànic
(`en-GB`), català (`ca-ES`) i xinès simplificat (`zh-CN`), a més dels
idiomes actius que hi hagi a la base de dades. `qps-ploc` queda reservat
per a proves de maquetació.

Per canviar-lo:

1. Selecciona l'usuari, el grup o l'abast al qual s'aplicarà el paràmetre.
2. Obre **Apariencia ▸ Idioma de la interfaz**.
3. Tria l'idioma. Per a `en-GB`, `ca-ES` o `zh-CN`, Factuzam obre el diàleg
   **Descargar traducción**. Si el paquet ja està instal·lat, el reutilitza;
   en cas contrari, l'obté del servei configurat mitjançant
   `appApiUrl` i `appApiToken`.
4. Espera que acabi la comprovació i prem **Guardar (F12)**. Les
   finestres obertes s'actualitzen en aquell moment; tanca i torna a obrir
   Factuzam per aplicar el canvi complet a tota la sessió.

La descàrrega necessita connexió al servei de Factuzam i un token amb
l'àmbit `descargar:traducciones`. El ZIP autenticat només s'instal·la després
de comprovar l'idioma, la versió del contracte, l'ordre i la mida dels seus
SQL i l'empremta SHA-256 declarada per a cada fitxer. Després de preparar
l'esquema, els SQL de dades s'instal·len en una transacció. Si falla la
descàrrega, la validació o la instal·lació, es mantenen l'idioma i el valor
anteriors.

L'idioma afecta formularis, menús, missatges, controls Developer
Express, tiquets i informes FastReport que tinguin traducció. Si falta una
clau, un idioma no està actiu o no es pot consultar la base de dades,
es conserva el text espanyol compilat com a alternativa; la pantalla mai
no queda buida per una traducció absent.

> `qps-ploc` allarga i marca els textos perquè l'equip de desenvolupament
> detecti rètols tallats. No és un idioma per treballar en producció.

#### Administració del catàleg

Les traduccions viuen al catàleg central `fza_traducciones`. La
utilitat independent **Editor de traducciones** (`utlTraduc`) permet a
l'administrador:

1. Connectar-se utilitzant l'INI de Factuzam.
2. Sincronitzar els textos espanyols coneguts per l'executable.
3. Triar un idioma i mostrar totes les claus o només les pendents.
4. Editar i desar les traduccions, conservant marcadors com `%s` i
   `%d`.

L'editor també admet una etiqueta nova, com `fr-FR`, sense modificar
l'executable. Els canvis es desen de manera transaccional i auditada.
Els textos escrits manualment per l'usuari dins d'un format d'informe
personalitzat no es tradueixen automàticament.

---

## Grupos de IVA

**Drecera de menú:** `[Ctrl]+[O]`

Defineix **agrupacions de tipus d'IVA** (zones/règims d'IVA). Serveix per
associar a empreses, clients i articles el conjunt de tipus impositius
que els correspon (p. ex. IVA peninsular enfront d'altres règims).

---

## Impuesto IVA

![Tipos de IVA y recargo de equivalencia](img/07-iva.png)

**Drecera de menú:** `[Ctrl]+[I]`

Manté els **tipus d'IVA** concrets i els seus percentatges (general,
reduït, superreduït…), juntament amb el **recàrrec d'equivalència**
associat a cadascun. És la base del càlcul d'impostos en compres i
vendes.

> Els percentatges d'IVA els fixa la normativa. No els canviïs llevat que
> canviï la llei; un tipus mal configurat afecta tota la facturació.

---

## Contadores

![Contadores de numeración por serie](img/07-contadores.png)

**Drecera de menú:** `[Ctrl]+[R]`

Gestiona els **comptadors de numeració** dels documents (factures,
albarans, comandes…) per **sèrie** i empresa. Cada document pren el seu número
correlatiu del comptador corresponent.

> Els números de factura han de ser **correlatius i sense buits** per
> exigència legal. No facis retrocedir ni reutilitzis comptadors de facturació.

---

## Formas de pago documentos

Catàleg de **formes de pagament** aplicables als documents de compra i
venda major (comptat, transferència, gir a X dies, etc.). Defineix
venciments i comportament de cobrament/pagament per a factures, comandes i
albarans.

Camps principals:

| Camp | Per a què serveix |
|------|-------------------|
| **Número de plazos** | Quants venciments genera en crear efectes o rebuts. |
| **Días entre plazos** | Separació entre venciments. |
| **% Adelanto** | Part que es cobra o paga per avançat. |
| **Ver Banco Empresa en Borrador** | Mostra la selecció de banc de l'empresa en generar cobraments o pagaments. |
| **Código Facturae** | Codi oficial `PaymentMeans` (`01` a `19`) utilitzat en emetre eDoc. |

Subpestanyes: **Más Datos**, **Ventas** (ús en vendes) i **Otros**.

![Formas de pago](img/03-formas-pago.png)

**Drecera de menú:** `[Shift]+[Ctrl]+[G]`

> No és el mateix manteniment que **Formas de Pago Caja**, que configura
> els botons i tipus de pagament del TPV.

---

## Usuarios, Grupos y Perfiles

Submenú de **seguretat**. Defineix qui entra a l'aplicació i què pot
fer.

### Usuarios

**Drecera de menú:** `[Ctrl]+[H]`

Alta i manteniment dels **usuaris** que accedeixen a Factuzam (els que
introdueixen credencials a l'[inici de sessió](00-acceso-y-primeros-pasos.md)).
Inclou la seva contrasenya, estat i el **perfil/grup** que determina els seus
permisos.

### Empleados

*(Sense drecera de menú; s'obre des del menú.)*

Fitxa d'**empleats** del negoci (dades de personal). Es pot vincular a
usuaris i a operacions de caixa per saber **qui** fa cada venda.

### Grupos

**Drecera de menú:** `[Ctrl]+[J]`

**Grups d'usuaris** per assignar permisos en bloc (p. ex. *Cajeros*,
*Administración*, *Encargados*). Un usuari hereta els permisos del seu grup.

### Perfiles

**Drecera de menú:** `[Ctrl]+[W]`

**Perfils de configuració** que personalitzen l'aparença i el
comportament de les pantalles (columnes visibles, títols, opcions)
per a un usuari o grup.

### Permisos

![Gestión de Permisos en árbol](img/07-permisos.png)

**Drecera de menú:** `[Ctrl]+[Q]`

Pantalla de **Gestión de Permisos** en forma d'**arbre**: activa o
desactiva, per grup/usuari, l'accés a cada **menú i acció** de
l'aplicació. És la forma recomanada de configurar la seguretat de manera
visual.

L'arbre replica el menú real de l'aplicació i permet treballar per:

- **Todos**, grup o usuari.
- Permetre, denegar o heretar una branca completa.
- Copiar permisos d'un subjecte a un altre, combinant-los o reemplaçant-los.
- Gestionar permisos de menú i permisos de pantalla: consultar, inserir,
  modificar, esborrar, exportar a Excel i imprimir.

A **Artículos ▸ Activar/desactivar web**, el permís específic controla
qui pot canviar la casella **En web** de la fitxa d'articles. Si
l'usuari no el té concedit, la casella queda en mode de només lectura i el
desament no pot alterar aquesta marca.

Quan un usuari autoritzat desmarca **En web**, Factuzam pregunta què cal fer:
**Sí** desactiva el producte a PrestaShop i deixa de sincronitzar-lo; **No**
només deixa de sincronitzar-lo i conserva el seu estat remot; **Cancelar** no
desa el canvi. En marcar **En web**, l'activació remota depèn del paràmetre
heretable **Activar artículos en PrestaShop al marcar En web** i, si està
autoritzada, s'executa únicament al final d'un procés correcte.

> Els canvis de permisos s'apliquen en el pròxim inici de sessió de l'usuari
> afectat.

### Permisos (tabla)

*(Sense drecera de menú; s'obre des del menú.)*

La mateixa informació de permisos presentada en **format de taula** (graella),
per a edició massiva o revisió ràpida de molts permisos alhora.

---

## Colas de envíos

La ruta **Otros ▸ Colas de envíos** reuneix en un sol lloc el seguiment
de les tres integracions:

### Verifactu

**Ruta:** *Otros ▸ Colas de envíos ▸ Verifactu*

Mostra les comunicacions fiscals pendents, en procés, enviades o amb
error. El seu ús i el reprocessament autoritzat s'expliquen al
[capítol Verifactu · Cola de envíos](11-verifactu.md#cola-de-envios).

### PrestaShop

**Ruta:** *Otros ▸ Colas de envíos ▸ PrestaShop*

Mostra els treballs de catàleg pendents, processats o amb error i
l'historial HTTP de cada intent. És una pantalla de diagnòstic de només
lectura: no modifica els treballs ni en reintenta l'execució. Consulta el detall operatiu a
[Integració amb PrestaShop ▸ Ventana de seguimiento](15-integracion-prestashop.md#ventana-de-seguimiento).

### Web Service Fzam

**Ruta:** *Otros ▸ Colas de envíos ▸ Web Service Fzam*

Aquesta cua publica en segon pla una còpia completa dels canvis de les
vendes per a serveis com **VentasFzam**. No és la cua fiscal de Verifactu i
l'espera o una caiguda de xarxa del servei no aturen el cobrament al TPV.

Els tipus d'esdeveniment que hi poden aparèixer són:

| Esdeveniment | Què representa |
|--------------|----------------|
| `VENTA_CONFIRMADA` | Alta o confirmació d'una venda. |
| `VENTA_ANULADA` | Anul·lació de la venda. |
| `VENTA_SUSTITUIDA` | Substitució per un altre document. |
| `VENTA_REABIERTA` | Reobertura controlada d'una venda. |
| `FISCAL_ACTUALIZADO` | Canvi posterior de la seva informació fiscal. |
| `TICKET_PDF_ACTUALIZADO` | Incorporació o actualització del PDF del tiquet. |
| `FACTURA_PDF_ACTUALIZADO` | Incorporació o actualització del PDF de la factura. |

La llista mostra esdeveniment, empresa, sèrie i número, tipus, estat, intents,
pròxim intent, data d'enviament, identificador de petició i darrer error. Els
estats són:

| Estat | Significat |
|-------|------------|
| **PENDIENTE** | Espera el cicle següent o la data del pròxim intent. |
| **PROCESANDO** | Un procés de l'aplicació ha reservat l'esdeveniment per enviar-lo. |
| **ENVIADA** | El servei ha acceptat l'esdeveniment i ha retornat un resultat correcte. |
| **ERROR** | S'ha exhaurit el màxim d'intents configurat. |

En seleccionar una fila, el plafó inferior presenta tots els seus intents HTTP:
mètode, recurs, estat HTTP, resultat, durada i identificador de petició.
Les pestanyes **Petición**, **Respuesta del servidor** i **Error** mostren el
contingut registrat; les credencials i els continguts binaris sensibles
s'ometen de l'historial.

- **Actualizar** torna a carregar la cua i el seu historial; no força cap enviament.
- **Ir a Documento** obre la factura o l'esborrany simplificat associat.

La finestra és de **només lectura**: no permet inserir, modificar, esborrar ni
reintentar cap fila. Els permisos `VentasWsCola.consultar`,
`VentasWsCola.excel` i `VentasWsCola.detalle` controlen respectivament
l'accés, l'exportació i la vista de petició/resposta. Un administrador veu
totes les empreses; els altres usuaris només veuen l'empresa de la seva sessió.
Sense empresa efectiva, la consulta no retorna files.

#### Cicle, reintents i recuperació

El procés consulta la cua cada **60 segons** de manera predeterminada
(`appVentasWsSegundosCiclo`; mínim 5 segons) i ho prova fins a **20 vegades**
(`appVentasWsMaxIntentos`). Després d'una fallada deixa la fila en `PENDIENTE`
i aplica una espera exponencial d'1, 2, 4, 8, 16, 32 i 64 minuts, amb un màxim
de 64 minuts per als intents posteriors. En exhaurir el límit passa a `ERROR`.

Si l'aplicació s'interromp amb una fila en `PROCESANDO`, la recupera com a
`PENDIENTE` quan fa més de deu minuts que està bloquejada. Després de corregir
una incidència de xarxa o configuració, les files que continuïn en `PENDIENTE`
seguiran soles en el pròxim intent. Una fila ja exhaurida en `ERROR` no es
torna a posar en cua des d'aquesta finestra: l'ha de revisar l'administrador o
el suport.

#### Configuració necessària

A **Otros ▸ Parámetros del entorno ▸ Servicios web** han de tenir valor:

- `appApiUrl`: URL general del servei web.
- `appApiToken`: clau API o token de la instal·lació.
- `appApiReferencia`: referència global de la instal·lació.

A més, a **TPV ▸ Parámetros de Caja ▸ Servicios web** cal activar
**Enviar ventas completas al webservice de respaldo**
(`vgerEnviarVentasWS`). El seu valor inicial és `False`; si està desactivat no
es creen esdeveniments nous. Els que ja estaven en cua continuen el seu cicle
fins que acaben o exhaureixen els intents. Consulta la posada en marxa de
l'aplicació mòbil a [VentasFzam](13-aplicaciones-moviles.md#puesta-en-marcha-administrador).

---

## Hacer Copia de Seguridad

![Diálogo de copia de seguridad](img/07-copia-seguridad.png)

**Drecera de menú:** `[Ctrl]+[Y]`

Inicia una **còpia de seguretat** de la base de dades. Genera un fitxer de
còpia amb les dades operatives (clients, articles, documents, estoc…).
A `fza_traducciones` inclou únicament els idiomes instal·lats des d'un
paquet descarregable. L'espanyol compilat i els catàlegs de treball no es
dupliquen; si mantens un idioma propi amb `utlTraduc`, conserva també el seu
SQL o una exportació administrativa independent.

> Fes còpies **amb regularitat** i desa-les en un lloc segur i
> extern a l'equip. És la teva única xarxa de seguretat davant d'una avaria de
> disc o una supressió accidental.

---

## Recuperar Copia de Seguridad

**Drecera de menú:** `[Ctrl]+[Z]`

Permet **restaurar** la base de dades a partir d'un fitxer de còpia o
**executar un script** de manteniment sobre la base de dades.

> ⚠️ **Operació delicada.** Restaurar una còpia **sobreescriu les dades
> actuals**. Assegura't de triar el fitxer correcte i que ningú no estigui
> treballant. En cas de dubte, fes primer una còpia de l'estat actual.

---

## Generador de Procesos

![Generador de Procesos con la pestaña Código SQL](img/07-generador-procesos.png)

**Drecera de menú:** `[Ctrl]+[G]`

Eina **avançada** per a administradors: permet escriure, desar i
executar **processos SQL** sobre la base de dades — des d'un **llistat a
mida** que no existeixi als menús fins a una **correcció massiva** de
dades o la crida a un procediment emmagatzemat.

Cada procés es desa com un registre més (amb **Código** i **Nombre de
proceso**), de manera que els llistats habituals queden en una **biblioteca
reutilitzable**: es localitzen a la Lista, s'obren i es tornen a executar.

### Les pestanyes de la pantalla

| Pestanya | Contingut |
|----------|-----------|
| **1_Código SQL** | Editor SQL amb acoloriment de sintaxi on s'escriu el procés. El botó **Bonito** reformata/indenta la sentència. |
| **2_Metadatos** | Arbre amb els objectes de la base de dades (taules, vistes i procediments) per ajudar a escriure. Amb subpestanyes **Estructura Metadato** (DDL de l'objecte) i **Vista Contenido** (dades de l'objecte). |
| **3_VistaDatos** | Graella amb el **resultat** de l'última execució. |
| **4_Otros** | Auditoria del procés (qui i quan el va crear/modificar). |

**Botons principals:** **Ejecutar (F5)** i **Script (F3)** (carrega un
fitxer `.sql`/`.txt` del disc com a procés nou, prenent-ne el nom del
fitxer). El menú contextual de l'editor ofereix també *Seleccionar Todo*,
*Ejecutar*, *Comentar* i *Abrir Script*.

### Com obtenir un llistat

1. Prem **Insertar registro** i dona **Código** i **Nombre** al procés
   (p. ex. `L001 — Ventas por familia`).
2. A **1_Código SQL** escriu la consulta `SELECT …`. Ajudes:
   - A **2_Metadatos**, l'arbre mostra totes les taules i vistes;
     fer **doble clic** sobre una taula/vista n'ensenya el contingut a *Vista
     Contenido*, i amb el focus a l'arbre **`[Ctrl]+[A]`** envia
     l'estructura de l'objecte a l'editor.
   - **Bonito** reformata l'SQL per fer-lo llegible.
3. Prem **Ejecutar (F5)**:
   - Si hi ha **text seleccionat** a l'editor, s'executa **només la selecció**; si no, s'executa tot el contingut.
   - El resultat s'obre a **3_VistaDatos**, amb el nombre de registres
     i el temps d'execució al plafó de resultats.
4. Treballa el resultat a la graella (ordenar, agrupar, filtrar) i
   extreu-lo amb **Exp. Excel** (exporta a Excel) o **Copiar Datos**
   (al porta-retalls).
5. Prem **Grabar** per conservar el procés i repetir el llistat quan
   calgui.

![Resultado de un listado en VistaDatos](img/07-generador-listado.png)

> El botó **Editar Grid** habilita l'edició directa del resultat sobre
> la base de dades. És útil per a correccions puntuals, però **modifica
> dades reals**: utilitza'l amb la mateixa cautela que un UPDATE.

### Com executar un procés (ordres i procediments)

- **Ordres** (`UPDATE`, `INSERT`, `DELETE`…): s'escriuen igual i
  s'executen amb **Ejecutar (F5)**. En lloc de graella, el plafó de
  resultats mostra les **files afectades** i el temps.
- **Procediments emmagatzemats**: a l'arbre de **2_Metadatos**, fes
  **doble clic** sobre el procediment: l'aplicació genera a l'editor
  la plantilla `CALL procedimiento(…)` amb els seus **paràmetres comentats**
  (nom i tipus de cadascun). Substitueix els comentaris pels valors i
  prem **Ejecutar (F5)**. Si el procediment retorna files, es mostren
  a **VistaDatos**; si no, s'informa com a ordre.
- **Diverses sentències alhora**: si l'editor conté diverses sentències
  separades per `;`, cadascuna s'executa a la seva **pròpia pestanya de
  resultat** (una graella per consulta, un registre de files afectades
  per ordre).
- **Executar per parts**: selecciona una sentència concreta i prem F5
  per executar **només aquesta part** — la forma més segura de provar un
  procés llarg pas a pas.

> Pensat per a usuaris tècnics. Una sentència mal escrita pot modificar
> o esborrar dades: **fes una còpia de seguretat abans d'un procés massiu**,
> prova primer amb un `SELECT` que mostri les files que tocaràs, i
> executa per selecció abans que l'script complet.

---

## Procesos auxiliares BBDD

**Ruta:** *Otros ▸ Procesos auxiliares BBDD*

Eina tècnica per inspeccionar les metadades de la base de dades. La
llista actual mostra les taules del catàleg i permet consultar-ne
l'**Estructura SQL** i el contingut; el doble clic obre els registres de la
taula activa.

| Acció | Resultat |
|-------|----------|
| **Refrescar metadatos** | Torna a llegir el catàleg de la base de dades actual. |
| **Ver contenido** | Obre els registres de la taula seleccionada en una graella. |
| **Copiar SQL** | Copia al porta-retalls l'estructura SQL mostrada. |
| **Exportar a Excel** | Exporta el contingut obert. |
| **Editar datos / Bloquear edición** | Habilita o torna a bloquejar l'edició directa de la graella. |

> És una opció per a usuaris tècnics autoritzats. **Editar datos** actua
> directament sobre la base real i també permet altes i supressions: fes una
> còpia de seguretat i evita utilitzar-la per al treball diari.

---

[◀ Menú Almacén](06-menu-almacen.md) · [Índex](README.md) · [Següent ▶ Menú Ayuda](08-menu-ayuda.md)
