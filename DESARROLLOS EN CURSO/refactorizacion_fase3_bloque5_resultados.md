# Fase 3 — Bloque B3: manejador único de menú (resultados)

Fecha: 27/07/2026. **Compilado Release/Win64: 0 errores** (306.962
líneas, −705 respecto a B2 al quitar los handlers). Probado en pantalla.
Ficheros: `inMtoPrincipal.pas`, `inMtoPrincipal.dfm`.

## Qué se ha hecho

**45 manejadores `OnClick` idénticos colapsados en uno.** Todos los menús
que solo hacían `if <item>.Visible then ShowMto(Self, 'CALL')` ahora
apuntan al mismo método:

```pascal
procedure TfrmMtoPrincipal.MenuGenericoClick(Sender: TObject);
var
  oItem: TMenuItem;
  sCall: string;
begin
  if (Sender is TMenuItem) then
  begin
    oItem := TMenuItem(Sender);
    if oItem.Visible then
    begin
      sCall := oFzaWinf.CallRegistrado(oItem);
      if sCall <> '' then
        ShowMto(Self, sCall);
    end;
  end;
end;
```

El CALL ya no está escrito a mano en cada handler: sale de
`fza_winforms` vía `TfzaWinF.CallRegistrado(item)` (el registro que montó
B2). El guardado por visibilidad se conserva, ahora genérico sobre
`Sender`. Resultado: **una pantalla nueva ya no necesita un handler
nuevo** — basta su fila en `fza_winforms` y poner `OnClick =
MenuGenericoClick` en el ítem.

## Cómo se eligieron los 45 (cruce automático, no a ojo)

Un script cruzó tres fuentes y solo colapsó los que casaban en las tres:

1. **Cuerpo del handler** (`inMtoPrincipal.pas`): exactamente
   `[inherited;] if <guard>.Visible then ShowMto(Self,'CALL')`, sin nada
   más.
2. **`.dfm`**: qué ítem de menú tiene ese handler en su `OnClick` (tenía
   que ser exactamente uno).
3. **`fza_winforms`**: `MENUITEM_WINF` de ese ítem → `CALL_WINF`.

Condición para colapsar: `guard == ítem` (así el `Visible` genérico es
equivalente) **y** `CALL de la BBDD == CALL del handler` (así
`CallRegistrado` devuelve exactamente lo que abría el handler viejo).
Los 45 cumplen las dos. Además se verificó que ninguno se llama
internamente (0 llamadas fuera del `.dfm`), 1 declaración y 1
implementación cada uno.

## Los 2 que NO se colapsaron (a propósito)

- **`Sesiones1Click`** (Compras → Sesiones): el ítem que de verdad
  dispara el handler es `mnuCrearArtculosyunpedidoounalbarn`, pero
  `fza_winforms` registra el menú de ComprasSesiones como `Sesiones1`.
  Como `CallRegistrado(mnuCrearArtculosyunpedidoounalbarn)` no
  resolvería, se deja su handler explícito. (Inconsistencia previa de
  datos, anotada; no la toco aquí.)
- **`Formasdepago2Click`**: es un segundo ítem de "Formas de pago" que
  no tiene fila propia en `fza_winforms` (`MENUITEM_WINF` registrado es
  `mnuFormasdePago`). Sin fila, el genérico no lo resolvería; se deja
  su handler.

Los handlers con lógica extra (modales, informes, relogin, parámetros)
tampoco se tocaron: `mnuCajaParam`, `CargarEfectosVenta1`,
`FacturarAlbaranes1`, `CargarEfectos1`, `mnuInvocarLogin`,
`mnuParmetrosdeEntorno`, `mnuVerifactuDeclaracion`,
`mnuBalanceAlmacenHorizontal`, `mnuTarifas`.

## Verificación

En frío: 45 impls + 45 declaraciones borradas, `MenuGenericoClick`
añadido (1 decl publicada + 1 impl), `.dfm` con 45 `OnClick =
MenuGenericoClick` y **cero** referencias a los handlers borrados,
balance begin/end cuadrado, sin líneas > 80.

En pantalla (build B3 corriendo, BBDD desarrollo):

- **Almacén → Movimientos de almacén** (clic de menú): abre
  "Movimientos de Almacén 2" con datos. → `MenuGenericoClick` resuelve
  `MovimientosAlmacen`. **OK**
- **Ctrl+K** (atajo de `mnuClientes`): abre "Clientes 2". → el mismo
  handler resuelve `Clientes` desde el atajo. **OK**

Menú y atajo, los dos caminos, resuelven el CALL correcto por el handler
único.

## Impacto

- `inMtoPrincipal` pierde 45 métodos clon (~225 líneas de boilerplate
  menos, un solo punto de mantenimiento).
- El fan-out del formulario principal baja: los menús de apertura ya no
  son 45 puntos que tocar, sino uno.
- Cierra el objetivo B3 del plan. El ciclo grande restante (14 unidades,
  entre formularios) es territorio de B4.

## Plan de pruebas para tu pasada (toca TODOS los menús de apertura)

1. Recorre los menús de apertura (Compras, Ventas Mayor, Caja, Almacén,
   Otros, Verifactu) y abre cada entrada: debe abrir la pantalla
   correcta. Son las 45 que ahora van por el handler único — conviene
   cubrirlas, es donde estaría un CALL mal resuelto.
2. Comprueba **Sesiones** (Compras) y el segundo **Formas de pago**: se
   dejaron con handler propio, deben seguir funcionando igual.
3. Usuario con permisos restringidos: los ítems sin permiso siguen
   ocultos y, si alguno quedara visible sin permiso, el guardado
   `Visible` del genérico lo respeta igual que antes.
4. Un par de atajos (Ctrl+K Clientes, Ctrl+M Movimientos, Ctrl+W
   Documentos de Trabajo): mismo handler, deben abrir su pantalla.
