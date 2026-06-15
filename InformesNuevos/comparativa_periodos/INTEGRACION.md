# Integración — Comparativa de periodos

Pasos para **aceptar** este desarrollo y llevarlo al árbol real de Factuzam.
Mientras no se acepte, el árbol real no contiene nada de esto.

## 1. Ficheros nuevos (copiar tal cual, respetando ruta)

Desde `comparativa_periodos/nuevos/` al raíz del repo:

- `src/Forms/inMtoComparativaMovimientos.pas`
- `src/Forms/inMtoComparativaMovimientos.dfm`
- `DESARROLLOS EN CURSO/comparativa_movimientos.sql`
- `DESARROLLOS EN CURSO/comparativa_movimientos.md`

El `.pas` está guardado en **UTF-8 con BOM** (como el resto de fuentes
Delphi); conservarlo al copiar.

## 2. Ficheros comunes (aplicar los cambios)

En `comparativa_periodos/comunes_modificados/` está cada común **con los
cambios ya hechos**. Se puede copiar encima del real, o aplicar a mano los
cambios que se listan abajo. Recomendado: revisar el diff antes de pisar.

### `fzam.dpr`
Añadida una línea en la cláusula `uses`, tras `inMtoAlmacenes`:
```pascal
  inMtoComparativaMovimientos in 'src\Forms\inMtoComparativaMovimientos.pas' {frmMtoComparativaMovimientos},
```

### `fzam.dproj`
Añadido un `DCCReference` tras el de `inMtoAlmacenes`:
```xml
        <DCCReference Include="src\Forms\inMtoComparativaMovimientos.pas">
            <Form>frmMtoComparativaMovimientos</Form>
        </DCCReference>
```

### `src/Core/inMtoPrincipal.dfm`
Nuevo menú principal **Informes** insertado antes de `mnuVerifactu`:
```
    object mnuInformes: TMenuItem
      Caption = '&Informes'
      object mnuComparativaMovimientos: TMenuItem
        Caption = 'Comparativa de periodos'
        OnClick = mnuComparativaMovimientosClick
      end
    end
```

### `src/Core/inMtoPrincipal.pas`
- Declaración del handler (sección de métodos, junto a los demás `mnu…Click`):
```pascal
    procedure mnuComparativaMovimientosClick(Sender: TObject);
```
- Implementación (junto al resto de handlers):
```pascal
procedure TfrmMtoPrincipal.mnuComparativaMovimientosClick(Sender: TObject);
begin
  if (mnuComparativaMovimientos.Visible) then
    ShowMto(Self, 'ComparativaMovimientos');
end;
```
`inMtoPrincipal.pas` ya hace `uses inLibShowMto`, no hace falta tocar el uses.

### `src/Lib/inLibGlobalVar.pas`
Bump de versión. **OJO**: la copia trae `…202606140060.alpha`, pero al
aceptar conviene re-bumpear a la fecha real de integración según la regla
del repo (mes/día/contador de 10 en 10). No copiar el número a ciegas.

## 3. Base de datos
Ejecutar el script idempotente `comparativa_movimientos.sql` en cada BBDD
(registra la pantalla en `fza_winforms` y el permiso en `fza_permisos`).

## 4. Verificación
Compilar `fzam.dproj`. Abrir **Informes ▸ Comparativa de periodos**.
Riesgo conocido: *unit scope* de TeeChart (`VCLTee.*`); si el entorno usa
otro, ajustar el `uses` del `.pas` (`TeEngine, Series, TeeProcs, Chart`).
