# Línea base recuperable previa a pruebas funcionales PrestaShop

Instantánea iniciada el 14/08/2026 a las 16:21:53 y cerrada con la lectura de
línea base del servidor a las 16:23:36 CEST. Sólo contiene el laboratorio
local. No se ha accedido a `herreras`, a producción ni a instalaciones legacy.

## Contenido

| Artefacto | Bytes | SHA-256 |
|---|---:|---|
| `factuzam_pre_pruebas_funcionales.sql` | 13.665.658 | `82382B4FA5C36A45EF64CA710434105EA554B9ED416F18C73691F0E7A108389A` |
| `prestashop_factuzam_lab_pre_pruebas_funcionales.sql` | 1.113.907 | `F8DAE9DA037EABF711E07F3909A8307CEE67EDF4CD17895757FFF6531BB52C92` |
| `prestashop_img_p_pre_pruebas_funcionales.zip` | 9.868.884 | `F55AC792689EAB4019963308BD4DF77E36D839ED3A31018D464BD1E8883A8E6B` |
| `prestashop_img_p_manifest.csv` | 90.211 | `D6DE9C9FBC14AE051A39F44BEE2AE92427C0818A431EF6D7F52D30F0687F9A82` |

Los volcados se generaron con MariaDB 12.3.2 mediante
`--single-transaction --quick --skip-lock-tables --routines --events
--triggers --hex-blob`. Todas las tablas de ambas bases son InnoDB, por lo que
la instantánea lógica es transaccionalmente consistente.

Validaciones realizadas sin restaurar:

- `factuzam`: 151 tablas, 97 vistas y 109 rutinas; el dump tiene marca final
  de terminación y 63.768 líneas.
- `prestashop_factuzam_lab`: 301 tablas; el dump tiene marca final de
  terminación y 20.220 líneas.
- Árbol `www/img/p`: 885 archivos, 11.427.567 bytes y huella lógica
  `C2AAB74841186CB0A7B5AE8C11E05A076E5B11D23ED6B81DBD9FD45548FE7B32`.
- Se leyó cada entrada del ZIP y se contrastó con el manifiesto: 885 de 885,
  cero diferencias de tamaño o SHA-256.

Línea base funcional:

| Dato | Valor |
|---|---:|
| Pendientes de la cola PrestaShop de FactuZam | 0 |
| Producto local `DEMO-CAMISA` | 1 |
| Productos PrestaShop | 19 |
| Combinaciones PrestaShop | 39 |
| Imágenes registradas PrestaShop | 23 |
| Clientes PrestaShop | 2 |
| Carritos PrestaShop | 5 |
| Pedidos PrestaShop | 5 |
| Producto PrestaShop con referencia `DEMO-CAMISA` | 0 |
| Permisos de webservice del laboratorio | 25 |

Las tablas nuevas de historial de las colas PrestaShop y Web Service Fzam no
existían todavía en `factuzam` al crear esta línea base.

## Verificar los artefactos

Desde PowerShell:

```powershell
$run = 'C:\DISCO_DURO\proyectos\Factuzam\tmp\prestashop_e2e\run_20260814_162153'
Get-Content -LiteralPath (Join-Path $run 'SHA256SUMS.txt') | ForEach-Object {
  $partes = $_ -split '  ', 2
  $obtenida = (Get-FileHash -LiteralPath (Join-Path $run $partes[1]) -Algorithm SHA256).Hash
  if ($obtenida -ne $partes[0]) {
    throw "Huella incorrecta: $($partes[1])"
  }
}
```

## Restauración exacta de las dos bases

Esta operación elimina los cambios posteriores a la instantánea. No debe
ejecutarse sin autorización expresa para restaurar. Antes hay que cerrar
FactuZam, detener el Apache del laboratorio y crear otro dump del estado que
se vaya a sustituir.

```powershell
$run = 'C:\DISCO_DURO\proyectos\Factuzam\tmp\prestashop_e2e\run_20260814_162153'
$cliente = 'C:\Program Files\MariaDB 12.3\bin\mariadb.exe'
$segura = Read-Host 'Contraseña del usuario root de MariaDB' -AsSecureString
$env:MYSQL_PWD = [Net.NetworkCredential]::new('', $segura).Password
try {
  & $cliente --protocol=TCP --host=127.0.0.1 --port=3306 --user=root --ssl=OFF `
    --execute='DROP DATABASE IF EXISTS `factuzam`; DROP DATABASE IF EXISTS `prestashop_factuzam_lab`;'
  if ($LASTEXITCODE -ne 0) {
    throw 'No se pudieron retirar las bases actuales; restauración cancelada.'
  }
  $ordenFactuzam = '"' + $cliente + '" --protocol=TCP --host=127.0.0.1 --port=3306 --user=root --ssl=OFF < "' +
    (Join-Path $run 'factuzam_pre_pruebas_funcionales.sql') + '"'
  & cmd.exe /d /c $ordenFactuzam
  if ($LASTEXITCODE -ne 0) {
    throw 'Falló la restauración de factuzam.'
  }
  $ordenPresta = '"' + $cliente + '" --protocol=TCP --host=127.0.0.1 --port=3306 --user=root --ssl=OFF < "' +
    (Join-Path $run 'prestashop_factuzam_lab_pre_pruebas_funcionales.sql') + '"'
  & cmd.exe /d /c $ordenPresta
  if ($LASTEXITCODE -ne 0) {
    throw 'Falló la restauración de prestashop_factuzam_lab.'
  }
} finally {
  Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
}
```

Después se deben comprobar los recuentos de la tabla anterior antes de
arrancar FactuZam o Apache.

## Restauración recuperable del árbol de imágenes

Con Apache detenido, este procedimiento conserva el árbol posterior a las
pruebas renombrándolo; no lo borra.

```powershell
$run = 'C:\DISCO_DURO\proyectos\Factuzam\tmp\prestashop_e2e\run_20260814_162153'
$img = 'C:\DISCO_DURO\proyectos\Factuzam\tmp\prestashop_factuzam_lab\www\img\p'
$imgAnterior = 'C:\DISCO_DURO\proyectos\Factuzam\tmp\prestashop_factuzam_lab\www\img\p_antes_restaurar_' +
  (Get-Date -Format 'yyyyMMdd_HHmmss')
$staging = Join-Path $run ('staging_img_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
if ((Test-Path -LiteralPath $imgAnterior) -or (Test-Path -LiteralPath $staging)) {
  throw 'Existe ya una ruta de destino; no se ha movido nada.'
}
Expand-Archive -LiteralPath (Join-Path $run 'prestashop_img_p_pre_pruebas_funcionales.zip') `
  -DestinationPath $staging
Move-Item -LiteralPath $img -Destination $imgAnterior
Move-Item -LiteralPath (Join-Path $staging 'p') -Destination $img
```

Tras el cambio se debe recalcular ruta, tamaño y SHA-256 de los 885 archivos y
contrastarlos con `prestashop_img_p_manifest.csv`. El árbol aparcado permite
revertir el movimiento si la validación no coincide.

## Alcance de lo ejecutado

Se han creado únicamente estos artefactos de respaldo. No se ha importado
ningún SQL, restaurado ninguna base, modificado ninguna imagen ni llamado a la
GUI o API de PrestaShop.
