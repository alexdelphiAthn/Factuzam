-- Publica el SQL base del piloto de sesiones de compra en perfiles.
-- Es idempotente y nunca sobrescribe una personalizacion existente.
INSERT INTO fza_usuarios_perfiles
  (USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER,
   VALUE_USUPER, VALUE_TEXT_USUPER,
   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)
SELECT
  'Todos',
  'SQL_REPOSITORIOS',
  'SQL__RepositorioComprasSesiones__ObtenerSiguienteLinea',
  'S;V=1',
  CONCAT(
    'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ',
    '  FROM fza_compras_sesiones_lineas ',
    ' WHERE SERIE_SES_SESLIN = :s ',
    '   AND NUMERO_SES_SESLIN = :n ',
    '   AND LINEA_SESLIN > :l'),
  NOW(), NOW(), 'Administrador', 'Administrador'
WHERE NOT EXISTS (
  SELECT 1
    FROM fza_usuarios_perfiles
   WHERE USUARIO_GRUPO_USUPER = 'Todos'
     AND KEY_USUPER = 'SQL_REPOSITORIOS'
     AND SUBKEY_USUPER =
       'SQL__RepositorioComprasSesiones__ObtenerSiguienteLinea');
INSERT INTO fza_usuarios_perfiles
  (USUARIO_GRUPO_USUPER, KEY_USUPER, SUBKEY_USUPER,
   VALUE_USUPER, VALUE_TEXT_USUPER,
   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF)
SELECT
  'Todos',
  'SQL_REPOSITORIOS',
  'SQL__RepositorioComprasSesiones__ConsultarCantidadesLinea',
  'S;V=1',
  CONCAT(
    'SELECT ID_AV_PIVOT_SESCEL, ',
    '       SUM(CANTIDAD_SESCEL) AS TOTAL ',
    '  FROM fza_compras_sesiones_celdas ',
    ' WHERE SERIE_SES_SESCEL = :s ',
    '   AND NUMERO_SES_SESCEL = :n ',
    '   AND LINEA_SES_SESCEL = :l ',
    ' GROUP BY ID_AV_PIVOT_SESCEL'),
  NOW(), NOW(), 'Administrador', 'Administrador'
WHERE NOT EXISTS (
  SELECT 1
    FROM fza_usuarios_perfiles
   WHERE USUARIO_GRUPO_USUPER = 'Todos'
     AND KEY_USUPER = 'SQL_REPOSITORIOS'
     AND SUBKEY_USUPER =
       'SQL__RepositorioComprasSesiones__ConsultarCantidadesLinea');
