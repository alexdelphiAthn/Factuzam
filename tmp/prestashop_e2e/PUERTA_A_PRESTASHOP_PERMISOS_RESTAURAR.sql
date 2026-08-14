-- Restauración exacta de permisos de la cuenta API del laboratorio.
-- Ejecutar solo contra 127.0.0.1:3306 al finalizar toda la batería.
USE prestashop_factuzam_lab;
START TRANSACTION;
DELETE permiso
FROM pslab_webservice_permission permiso
INNER JOIN pslab_webservice_account cuenta
  ON cuenta.id_webservice_account=permiso.id_webservice_account
WHERE cuenta.id_webservice_account=1
AND cuenta.description='FactuZam laboratorio local'
AND NOT (
  (permiso.resource='combinations' AND permiso.method IN ('GET','PATCH'))
  OR (permiso.resource='products' AND permiso.method IN ('GET','PATCH'))
  OR (permiso.resource='shops' AND permiso.method='GET')
  OR (permiso.resource='stock_availables' AND permiso.method IN ('GET','PATCH'))
);
INSERT INTO pslab_webservice_permission
  (resource,method,id_webservice_account)
SELECT objetivo.resource,objetivo.method,cuenta.id_webservice_account
FROM pslab_webservice_account cuenta
CROSS JOIN (
  SELECT 'combinations' AS resource,'GET' AS method
  UNION ALL SELECT 'combinations','PATCH'
  UNION ALL SELECT 'products','GET'
  UNION ALL SELECT 'products','PATCH'
  UNION ALL SELECT 'shops','GET'
  UNION ALL SELECT 'stock_availables','GET'
  UNION ALL SELECT 'stock_availables','PATCH'
) objetivo
WHERE cuenta.id_webservice_account=1
AND cuenta.description='FactuZam laboratorio local'
AND cuenta.active=1
AND NOT EXISTS (
  SELECT 1
  FROM pslab_webservice_permission actual
  WHERE actual.id_webservice_account=cuenta.id_webservice_account
  AND actual.resource=objetivo.resource
  AND actual.method=objetivo.method
);
COMMIT;
SELECT resource,method
FROM pslab_webservice_permission
WHERE id_webservice_account=1
ORDER BY resource,method;
