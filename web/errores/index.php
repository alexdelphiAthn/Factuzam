<?php
declare(strict_types=1);

require_once __DIR__ . '/lib.php';

$usuarioAdmin = exigir_admin();
$db = bbdd();
$mensajePagina = '';

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    validar_csrf((string)($_POST['csrf'] ?? ''));
    $id = (int)($_POST['id_error'] ?? 0);
    $estadoNuevo = limpiar_texto($_POST['estado'] ?? '', 30);
    $respuesta = limpiar_texto($_POST['respuesta'] ?? '', 10000);
    if ($id <= 0 || !estado_valido($estadoNuevo)) {
        http_response_code(400);
        exit('Datos no válidos.');
    }
    try {
        $db->beginTransaction();
        $consulta = $db->prepare(
            'SELECT * FROM soporte_errores WHERE ID_ERROR = :id FOR UPDATE'
        );
        $consulta->execute([':id' => $id]);
        $errorActual = $consulta->fetch();
        if (!is_array($errorActual)) {
            throw new RuntimeException('Incidencia no encontrada.');
        }
        $estadoAnterior = (string)$errorActual['ESTADO_ERROR'];
        if ($estadoNuevo !== $estadoAnterior) {
            $consulta = $db->prepare(
                'UPDATE soporte_errores SET ESTADO_ERROR = :estado, ' .
                'USUARIO_MODIF = :usuario WHERE ID_ERROR = :id'
            );
            $consulta->execute([
                ':estado' => $estadoNuevo,
                ':usuario' => $usuarioAdmin,
                ':id' => $id,
            ]);
            registrar_estado(
                $db,
                $id,
                $estadoAnterior,
                $estadoNuevo,
                $usuarioAdmin,
                'Cambio desde la consola del desarrollador'
            );
        }
        $idComunicacion = 0;
        if ($respuesta !== '') {
            $sql = 'INSERT INTO soporte_error_comunicaciones (' .
                'ID_ERROR, ORIGEN_COMUNICACION, MENSAJE_COMUNICACION, ' .
                'ESEMAIL_ENVIADO, EMAIL_DESTINO, USUARIO_ALTA, ' .
                'USUARIO_MODIF) VALUES (:id, :origen, :mensaje, :enviado, ' .
                ':email, :alta, :modif)';
            $consulta = $db->prepare($sql);
            $consulta->execute([
                ':id' => $id,
                ':origen' => 'DESARROLLADOR',
                ':mensaje' => $respuesta,
                ':enviado' => 'N',
                ':email' => $errorActual['EMAIL_CONTACTO'],
                ':alta' => $usuarioAdmin,
                ':modif' => $usuarioAdmin,
            ]);
            $idComunicacion = (int)$db->lastInsertId();
        }
        $db->commit();
        if ($idComunicacion > 0) {
            $enviado = enviar_correo(
                (string)$errorActual['EMAIL_CONTACTO'],
                'Respuesta a ' . $errorActual['REFERENCIA_ERROR'],
                $respuesta
            );
            if ($enviado) {
                $consulta = $db->prepare(
                    'UPDATE soporte_error_comunicaciones ' .
                    'SET ESEMAIL_ENVIADO = :enviado, USUARIO_MODIF = :usuario ' .
                    'WHERE ID_COMUNICACION = :id'
                );
                $consulta->execute([
                    ':enviado' => 'S',
                    ':usuario' => $usuarioAdmin,
                    ':id' => $idComunicacion,
                ]);
            }
        }
        header('Location: index.php?id=' . $id . '&guardado=1');
        exit;
    } catch (Throwable $excepcion) {
        if ($db->inTransaction()) {
            $db->rollBack();
        }
        error_log('errores/index.php: ' . $excepcion->getMessage());
        $mensajePagina = 'No se pudieron guardar los cambios.';
    }
}

$idSeleccionado = (int)($_GET['id'] ?? 0);
$estadoFiltro = limpiar_texto($_GET['estado'] ?? '', 30);
$textoFiltro = limpiar_texto($_GET['q'] ?? '', 120);
$parametros = [];
$condiciones = [];
if ($estadoFiltro !== '' && estado_valido($estadoFiltro)) {
    $condiciones[] = 'ESTADO_ERROR = :estado';
    $parametros[':estado'] = $estadoFiltro;
}
if ($textoFiltro !== '') {
    $condiciones[] = '(REFERENCIA_ERROR LIKE :texto OR ' .
        'REFERENCIA_CLIENTE LIKE :texto OR EMAIL_CONTACTO LIKE :texto OR ' .
        'MENSAJE_ERROR LIKE :texto)';
    $parametros[':texto'] = '%' . $textoFiltro . '%';
}
$sql = 'SELECT ID_ERROR, REFERENCIA_ERROR, REFERENCIA_CLIENTE, ' .
    'EMAIL_CONTACTO, CLASE_ERROR, MENSAJE_ERROR, ESLOG_COMPLETO, ' .
    'ESTADO_ERROR, INSTANTE_ALTA, EXISTS (' .
    'SELECT 1 FROM soporte_error_adjuntos sea ' .
    'WHERE sea.ID_ERROR = soporte_errores.ID_ERROR ' .
    "AND sea.TIPO_ADJUNTO = 'COPIA_SEGURIDAD') AS ESCOPIA_SEGURIDAD " .
    'FROM soporte_errores';
if ($condiciones !== []) {
    $sql .= ' WHERE ' . implode(' AND ', $condiciones);
}
$sql .= ' ORDER BY INSTANTE_ALTA DESC LIMIT 200';
$consulta = $db->prepare($sql);
$consulta->execute($parametros);
$errores = $consulta->fetchAll();

$detalle = null;
$adjuntos = [];
$comunicaciones = [];
$historial = [];
$tieneCopiaSeguridad = false;
if ($idSeleccionado > 0) {
    $consulta = $db->prepare(
        'SELECT * FROM soporte_errores WHERE ID_ERROR = :id'
    );
    $consulta->execute([':id' => $idSeleccionado]);
    $detalle = $consulta->fetch();
    if (is_array($detalle)) {
        $consulta = $db->prepare(
            'SELECT * FROM soporte_error_adjuntos ' .
            'WHERE ID_ERROR = :id ORDER BY ID_ADJUNTO'
        );
        $consulta->execute([':id' => $idSeleccionado]);
        $adjuntos = $consulta->fetchAll();
        foreach ($adjuntos as $adjunto) {
            if ($adjunto['TIPO_ADJUNTO'] === 'COPIA_SEGURIDAD') {
                $tieneCopiaSeguridad = true;
            }
        }
        $comunicaciones = comunicaciones_error($db, $idSeleccionado);
        $consulta = $db->prepare(
            'SELECT * FROM soporte_error_estados ' .
            'WHERE ID_ERROR = :id ORDER BY INSTANTE_ALTA, ID_ESTADO'
        );
        $consulta->execute([':id' => $idSeleccionado]);
        $historial = $consulta->fetchAll();
    }
}
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Errores Factuzam</title>
  <style>
    :root { --ink:#142038; --muted:#6c778d; --line:#dfe5ef; --brand:#2855d9;
      --bg:#f4f7fb; --paper:#fff; --danger:#a12727; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--bg); color:var(--ink);
      font:14px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif; }
    header { position:sticky; top:0; z-index:2; display:flex; align-items:center;
      justify-content:space-between; padding:14px 22px; background:#142038;
      color:#fff; box-shadow:0 6px 24px #14203833; }
    h1,h2,h3 { margin:0 0 12px; line-height:1.2; }
    header h1 { font-size:20px; margin:0; }
    .layout { display:grid; grid-template-columns:minmax(410px,42%) 1fr;
      gap:18px; padding:18px; min-height:calc(100vh - 58px); }
    .panel { background:var(--paper); border:1px solid var(--line);
      border-radius:14px; box-shadow:0 10px 30px #25365b0d; overflow:hidden; }
    .filtros { display:flex; gap:8px; padding:14px; border-bottom:1px solid var(--line); }
    input,select,textarea { border:1px solid #bac5d7; border-radius:8px;
      padding:9px 10px; font:inherit; background:#fff; }
    .filtros input { min-width:0; flex:1; }
    button { border:0; border-radius:8px; padding:9px 14px; color:#fff;
      background:var(--brand); font-weight:700; cursor:pointer; }
    table { width:100%; border-collapse:collapse; }
    th,td { padding:10px 12px; border-bottom:1px solid #edf0f5;
      text-align:left; vertical-align:top; }
    th { color:var(--muted); font-size:12px; text-transform:uppercase; }
    tr:hover td { background:#f8faff; }
    a { color:#214dc7; text-decoration:none; }
    .estado { display:inline-block; border-radius:999px; background:#eaf0ff;
      color:#2046b5; padding:3px 8px; font-size:12px; font-weight:800; }
    .incompleto { color:var(--danger); font-weight:800; }
    .detalle { padding:20px; overflow:auto; }
    .meta { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:8px 24px;
      padding:14px; background:#f7f9fd; border-radius:10px; margin-bottom:18px; }
    .meta dt { color:var(--muted); font-size:12px; }
    .meta dd { margin:1px 0 0; overflow-wrap:anywhere; }
    pre { white-space:pre-wrap; overflow-wrap:anywhere; background:#101827; color:#e7edf8;
      padding:16px; border-radius:10px; max-height:420px; overflow:auto; }
    .mensaje { border-left:4px solid var(--brand); padding:10px 12px;
      background:#f7f9ff; margin:10px 0; white-space:pre-wrap; }
    .cliente { border-left-color:#16a06d; background:#f2fbf7; }
    textarea { width:100%; min-height:100px; resize:vertical; margin-top:8px; }
    .acciones { border-top:1px solid var(--line); margin-top:20px; padding-top:18px; }
    .aviso { color:var(--danger); font-weight:700; }
    @media (max-width:980px) { .layout { grid-template-columns:1fr; }
      .meta { grid-template-columns:1fr; } }
  </style>
</head>
<body>
<header>
  <h1>Incidencias Factuzam</h1>
  <span><?= escapar($usuarioAdmin) ?></span>
</header>
<main class="layout">
  <section class="panel">
    <form class="filtros" method="get">
      <input name="q" value="<?= escapar($textoFiltro) ?>" placeholder="Referencia, cliente, email o error">
      <select name="estado">
        <option value="">Todos los estados</option>
        <?php foreach (ESTADOS_ERROR as $estado): ?>
          <option value="<?= escapar($estado) ?>" <?= $estadoFiltro === $estado ? 'selected' : '' ?>><?= escapar($estado) ?></option>
        <?php endforeach; ?>
      </select>
      <button>Filtrar</button>
    </form>
    <table>
      <thead><tr><th>Incidencia</th><th>Estado</th><th>Recibida</th></tr></thead>
      <tbody>
      <?php foreach ($errores as $error): ?>
        <tr>
          <td><a href="?id=<?= (int)$error['ID_ERROR'] ?>"><strong><?= escapar((string)$error['REFERENCIA_ERROR']) ?></strong></a><br>
            <?= escapar((string)$error['CLASE_ERROR']) ?> · <?= escapar((string)$error['MENSAJE_ERROR']) ?><br>
            <small><?= escapar((string)$error['REFERENCIA_CLIENTE']) ?> · <?= escapar((string)$error['EMAIL_CONTACTO']) ?></small>
            <?php if (!(bool)$error['ESCOPIA_SEGURIDAD'] && $error['ESLOG_COMPLETO'] !== 'S'): ?><br><span class="incompleto">LOG incompleto</span><?php endif; ?>
          </td>
          <td><span class="estado"><?= escapar((string)$error['ESTADO_ERROR']) ?></span></td>
          <td><?= escapar((string)$error['INSTANTE_ALTA']) ?><br><small>UTC</small></td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  </section>
  <section class="panel detalle">
  <?php if (!is_array($detalle)): ?>
    <h2>Seleccione una incidencia</h2>
    <p>Abra una referencia de la lista para revisar evidencias y comunicarse con el cliente.</p>
  <?php else: ?>
    <span class="estado"><?= escapar((string)$detalle['ESTADO_ERROR']) ?></span>
    <h2><?= escapar((string)$detalle['REFERENCIA_ERROR']) ?></h2>
    <?php if (isset($_GET['guardado'])): ?><p><strong>Cambios guardados.</strong></p><?php endif; ?>
    <?php if ($mensajePagina !== ''): ?><p class="aviso"><?= escapar($mensajePagina) ?></p><?php endif; ?>
    <dl class="meta">
      <div><dt>Cliente</dt><dd><?= escapar((string)$detalle['REFERENCIA_CLIENTE']) ?></dd></div>
      <div><dt>Contacto</dt><dd><a href="mailto:<?= escapar((string)$detalle['EMAIL_CONTACTO']) ?>"><?= escapar((string)$detalle['EMAIL_CONTACTO']) ?></a> · <?= escapar((string)$detalle['TELEFONO_CONTACTO']) ?></dd></div>
      <div><dt>Versión</dt><dd><?= escapar((string)$detalle['APLICACION']) ?> <?= escapar((string)$detalle['VERSION_APLICACION']) ?></dd></div>
      <div><dt>Licencia</dt><dd><?= escapar((string)$detalle['MODO_LICENCIA']) ?> · <?= escapar((string)$detalle['ESTADO_LICENCIA']) ?></dd></div>
      <div><dt>Ubicación</dt><dd><?= escapar((string)$detalle['EMPRESA_CLIENTE']) ?> / <?= escapar((string)$detalle['ALMACEN_CLIENTE']) ?> / <?= escapar((string)$detalle['CAJA_CLIENTE']) ?></dd></div>
      <div><dt>Usuario y equipo</dt><dd><?= escapar((string)$detalle['USUARIO_CLIENTE']) ?> · <?= escapar((string)$detalle['EQUIPO_CLIENTE']) ?></dd></div>
      <?php if ($tieneCopiaSeguridad): ?>
      <div><dt>Evidencia</dt><dd>Copia de seguridad protegida</dd></div>
      <?php else: ?>
      <div><dt>LOG</dt><dd>SQL <?= escapar((string)$detalle['ESLOG_SQL']) ?> · rendimiento <?= escapar((string)$detalle['ESLOG_RENDIMIENTO']) ?> · avanzado <?= escapar((string)$detalle['ESLOG_AVANZADO']) ?></dd></div>
      <?php endif; ?>
    </dl>
    <h3>Descripción del cliente</h3>
    <p><?= nl2br(escapar((string)$detalle['DESCRIPCION_CLIENTE'])) ?></p>
    <h3><?= escapar((string)$detalle['CLASE_ERROR']) ?></h3>
    <p class="aviso"><?= escapar((string)$detalle['MENSAJE_ERROR']) ?></p>
    <pre><?= escapar((string)$detalle['DETALLE_ERROR']) ?></pre>
    <h3>Adjuntos</h3>
    <?php if ($adjuntos === []): ?><p>No se recibieron adjuntos.</p><?php endif; ?>
    <?php foreach ($adjuntos as $adjunto): ?>
      <a href="adjunto.php?id=<?= (int)$adjunto['ID_ADJUNTO'] ?>"><?= escapar((string)$adjunto['TIPO_ADJUNTO']) ?> · <?= number_format((int)$adjunto['TAMANO_BYTES'] / 1024, 1, ',', '.') ?> KiB</a><br>
    <?php endforeach; ?>
    <h3 style="margin-top:20px">Comunicación</h3>
    <?php foreach ($comunicaciones as $comunicacion): ?>
      <div class="mensaje <?= $comunicacion['ORIGEN_COMUNICACION'] === 'CLIENTE' ? 'cliente' : '' ?>"><strong><?= escapar((string)$comunicacion['ORIGEN_COMUNICACION']) ?></strong> · <?= escapar((string)$comunicacion['INSTANTE_ALTA']) ?> UTC
<?= escapar((string)$comunicacion['MENSAJE_COMUNICACION']) ?></div>
    <?php endforeach; ?>
    <form class="acciones" method="post">
      <input type="hidden" name="csrf" value="<?= escapar(token_csrf()) ?>">
      <input type="hidden" name="id_error" value="<?= (int)$detalle['ID_ERROR'] ?>">
      <label for="estado"><strong>Estado</strong></label><br>
      <select id="estado" name="estado">
        <?php foreach (ESTADOS_ERROR as $estado): ?>
          <option value="<?= escapar($estado) ?>" <?= $detalle['ESTADO_ERROR'] === $estado ? 'selected' : '' ?>><?= escapar($estado) ?></option>
        <?php endforeach; ?>
      </select>
      <textarea name="respuesta" maxlength="10000" placeholder="Respuesta para el cliente (opcional)"></textarea>
      <button type="submit">Guardar y comunicar</button>
    </form>
    <details style="margin-top:20px"><summary>Historial de estados</summary><ul>
      <?php foreach ($historial as $cambio): ?><li><?= escapar((string)$cambio['INSTANTE_ALTA']) ?> · <?= escapar((string)$cambio['ESTADO_ANTERIOR']) ?> → <?= escapar((string)$cambio['ESTADO_NUEVO']) ?> · <?= escapar((string)$cambio['USUARIO_ALTA']) ?></li><?php endforeach; ?>
    </ul></details>
  <?php endif; ?>
  </section>
</main>
</body>
</html>
