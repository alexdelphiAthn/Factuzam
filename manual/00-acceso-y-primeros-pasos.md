# 00 · Acceso y primeros pasos

[◀ Volver al índice](README.md)

Este capítulo describe lo que ocurre desde que arrancas Factuzam hasta que
tienes la ventana principal lista para trabajar.

---

## 1. Pantalla de presentación (Splash)

Al ejecutar la aplicación se muestra durante unos segundos la pantalla de
presentación con el logotipo y el **número de versión**. Es informativa; no
requiere ninguna acción. La misma pantalla puede consultarse en cualquier
momento desde *Ayuda ▸ Acerca de*.

![Pantalla de presentación](img/00-splash.png)
*▢ Captura pendiente — Pantalla de presentación (Splash).*

---

## 2. Inicio de sesión (Login)

A continuación aparece la ventana **Login FactuZam**:

![Ventana de login](img/00-login.png)
*▢ Captura pendiente — Ventana de login.*

| Campo | Descripción |
|-------|-------------|
| **Usuario** | Nombre de usuario de la aplicación. |
| **Contraseña** | Clave del usuario. |
| **Recordar Usuario** | Guarda el usuario para el próximo arranque. |
| **Recordar Contraseña** | Guarda también la contraseña (úsalo solo en equipos de confianza). |
| **Arranque sin login** | Si se marca, la aplicación entra directamente la próxima vez sin pedir credenciales. |

**Botones:**

- **Aceptar (F12)** — valida las credenciales y entra a la aplicación.
- **Salir (Esc)** — cierra la aplicación sin entrar.

> El usuario determina tu **perfil de permisos**, que decide qué menús y
> qué acciones tienes disponibles dentro de la aplicación.

---

## 3. Configuración de la base de datos

Desde la propia ventana de login, el botón **Configurar Base de Datos ▸**
despliega el panel **Configuración BBDD**. Aquí se indican los datos de
conexión al servidor **MariaDB/MySQL** donde residen los datos:

![Panel de configuración de BBDD](img/00-config-bbdd.png)
*▢ Captura pendiente — Login con el panel Configuración BBDD desplegado.*

| Campo | Descripción |
|-------|-------------|
| **Host** | Servidor donde está la base de datos (p. ej. `localhost` o una IP). |
| **Puerto** | Puerto del servidor (MariaDB usa `3306` por defecto). |
| **Nombre BD** | Nombre de la base de datos de Factuzam. |
| **Usuario** | Usuario de la base de datos. |
| **Contraseña** | Clave del usuario de la base de datos. |

**Botones del panel:**

- **Probar Conexión** — comprueba que los datos son correctos y que el
  servidor responde, sin necesidad de entrar.
- **Configurar/cambiar credenciales del servidor** (`...`) — utilidades
  avanzadas de administración de la conexión.

> Esta configuración normalmente la realiza **una sola vez el instalador o
> administrador**. Un usuario habitual no necesita tocarla. Si al arrancar
> aparece un error de conexión, avisa al administrador antes de cambiar
> nada aquí.

---

## 4. La ventana principal

Tras validar el login se muestra la ventana principal de Factuzam, con:

![Ventana principal](img/00-principal.png)
*▢ Captura pendiente — Ventana principal con varias pestañas abiertas.*

- La **barra de menú** en la parte superior (Archivo, Compras, Ventas
  Mayor, Caja, Almacén, Otros, Ayuda). Es el eje de navegación de toda la
  aplicación y la estructura que sigue este manual.
- Un **área de trabajo con pestañas**: cada opción de menú que abres se
  carga como una pestaña dentro de la ventana principal, de modo que
  puedes tener varias pantallas abiertas a la vez y cambiar entre ellas.
- Una **barra de estado** inferior con información de contexto (usuario,
  empresa activa, versión…).

### Cómo se abren las pantallas

Cuando eliges una opción de menú, la aplicación abre la pantalla de
mantenimiento correspondiente **como una pestaña nueva** (o reutiliza la
que ya esté abierta). Algunas pantallas admiten **varias instancias
simultáneas** (verás un número junto al título, p. ej. *Clientes 2*); una
de esas instancias queda reservada para las **búsquedas rápidas** con
`[Ctrl]+[A]`.

> El funcionamiento interno de cada pantalla (lista, ficha, búsqueda,
> navegación, grabado…) es **común a casi todos los mantenimientos** y se
> explica una sola vez en el capítulo
> [01 · Conceptos comunes](01-conceptos-comunes.md). Conviene leerlo antes
> de los capítulos de cada menú.

---

[◀ Índice](README.md) · [Siguiente ▶ Conceptos comunes](01-conceptos-comunes.md)
