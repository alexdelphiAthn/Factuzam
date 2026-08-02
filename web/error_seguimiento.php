<?php
declare(strict_types=1);

require_once __DIR__ . '/errores/lib.php';

$referencia = limpiar_texto($_REQUEST['referencia'] ?? '', 40);
$token = limpiar_texto($_REQUEST['token'] ?? '', 100);
$db = bbdd();
$error = obtener_error_seguimiento($db, $referencia, $token);
if (!is_array($error)) {
    http_response_code(404);
    exit('No se encontró la incidencia o el enlace no es válido.');
}

$mensajeEstado = isset($_GET['enviado'])
    ? 'Mensaje enviado al desarrollador.'
    : '';
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    validar_csrf((string)($_POST['csrf'] ?? ''));
    $mensaje = limpiar_texto($_POST['mensaje'] ?? '', 10000);
    if ($mensaje === '') {
        $mensajeEstado = 'Escriba un mensaje antes de enviarlo.';
    } else {
        try {
            $db->beginTransaction();
            $sql = 'INSERT INTO soporte_error_comunicaciones (' .
                'ID_ERROR, ORIGEN_COMUNICACION, MENSAJE_COMUNICACION, ' .
                'ESEMAIL_ENVIADO, USUARIO_ALTA, USUARIO_MODIF) VALUES (' .
                ':id, :origen, :mensaje, :email, :alta, :modif)';
            $consulta = $db->prepare($sql);
            $consulta->execute([
                ':id' => (int)$error['ID_ERROR'],
                ':origen' => 'CLIENTE',
                ':mensaje' => $mensaje,
                ':email' => 'N',
                ':alta' => 'CLIENTE',
                ':modif' => 'CLIENTE',
            ]);
            $anterior = (string)$error['ESTADO_ERROR'];
            $sql = 'UPDATE soporte_errores SET ESTADO_ERROR = :estado, ' .
                'USUARIO_MODIF = :usuario WHERE ID_ERROR = :id';
            $consulta = $db->prepare($sql);
            $consulta->execute([
                ':estado' => 'RESPONDIDO',
                ':usuario' => 'CLIENTE',
                ':id' => (int)$error['ID_ERROR'],
            ]);
            if ($anterior !== 'RESPONDIDO') {
                registrar_estado(
                    $db,
                    (int)$error['ID_ERROR'],
                    $anterior,
                    'RESPONDIDO',
                    'CLIENTE',
                    'Respuesta desde el seguimiento público'
                );
            }
            $db->commit();
            notificar_desarrollador($referencia, $mensaje);
            header('Location: error_seguimiento.php?' . http_build_query([
                'referencia' => $referencia,
                'token' => $token,
                'enviado' => '1',
            ]));
            exit;
        } catch (Throwable $excepcion) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            error_log('error_seguimiento.php: ' . $excepcion->getMessage());
            $mensajeEstado = 'No se pudo enviar el mensaje.';
        }
    }
}
$comunicaciones = comunicaciones_error($db, (int)$error['ID_ERROR']);
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Seguimiento <?= escapar($referencia) ?> · Factuzam</title>
  <style>
    :root { color-scheme: light; --ink:#172033; --muted:#65718a;
      --line:#dfe5ef; --brand:#2855d9; --paper:#fff; --bg:#f4f7fb; }
    * { box-sizing:border-box; }
    body { margin:0; background:var(--bg); color:var(--ink);
      font:16px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif; }
    main { width:min(860px,calc(100% - 32px)); margin:48px auto; }
    header, section { background:var(--paper); border:1px solid var(--line);
      border-radius:16px; padding:24px; box-shadow:0 12px 36px #25365b12; }
    section { margin-top:18px; }
    h1,h2 { margin:0 0 10px; line-height:1.2; }
    h1 { font-size:clamp(26px,5vw,40px); }
    h2 { font-size:20px; }
    .meta { display:flex; flex-wrap:wrap; gap:10px 22px; color:var(--muted); }
    .estado { display:inline-block; padding:5px 10px; border-radius:999px;
      background:#eaf0ff; color:#2046b5; font-weight:700; }
    .mensaje { border-left:4px solid var(--brand); padding:12px 16px;
      margin:14px 0; background:#f7f9ff; border-radius:8px; white-space:pre-wrap; }
    .cliente { border-left-color:#17a673; background:#f1fbf7; }
    label { display:block; font-weight:700; margin-bottom:8px; }
    textarea { width:100%; min-height:130px; resize:vertical; border:1px solid #bbc5d8;
      border-radius:10px; padding:12px; font:inherit; }
    button { margin-top:12px; border:0; border-radius:10px; padding:12px 18px;
      color:#fff; background:var(--brand); font:700 15px inherit; cursor:pointer; }
    .aviso { margin:12px 0; color:#135c45; font-weight:700; }
  </style>
</head>
<body>
<main>
  <header>
    <span class="estado"><?= escapar((string)$error['ESTADO_ERROR']) ?></span>
    <h1>Seguimiento del error</h1>
    <div class="meta">
      <span>Referencia: <strong><?= escapar($referencia) ?></strong></span>
      <span>Recibido: <?= escapar((string)$error['INSTANTE_ALTA']) ?> UTC</span>
    </div>
  </header>
  <section>
    <h2>Comunicación</h2>
    <?php if ($comunicaciones === []): ?>
      <p>Aún no hay mensajes. El desarrollador revisará la incidencia.</p>
    <?php endif; ?>
    <?php foreach ($comunicaciones as $comunicacion): ?>
      <article class="mensaje <?= $comunicacion['ORIGEN_COMUNICACION'] === 'CLIENTE' ? 'cliente' : '' ?>">
        <strong><?= $comunicacion['ORIGEN_COMUNICACION'] === 'CLIENTE' ? 'Cliente' : 'Desarrollador' ?></strong>
        · <?= escapar((string)$comunicacion['INSTANTE_ALTA']) ?> UTC<br>
        <?= nl2br(escapar((string)$comunicacion['MENSAJE_COMUNICACION'])) ?>
      </article>
    <?php endforeach; ?>
  </section>
  <section>
    <h2>Responder</h2>
    <?php if ($mensajeEstado !== ''): ?>
      <p class="aviso"><?= escapar($mensajeEstado) ?></p>
    <?php endif; ?>
    <form method="post">
      <input type="hidden" name="referencia" value="<?= escapar($referencia) ?>">
      <input type="hidden" name="token" value="<?= escapar($token) ?>">
      <input type="hidden" name="csrf" value="<?= escapar(token_csrf()) ?>">
      <label for="mensaje">Mensaje para el desarrollador</label>
      <textarea id="mensaje" name="mensaje" maxlength="10000" required></textarea>
      <button type="submit">Enviar mensaje</button>
    </form>
  </section>
</main>
</body>
</html>
