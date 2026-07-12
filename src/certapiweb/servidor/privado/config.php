<?php
declare(strict_types=1);

// Copiar como config.php y mantener fuera del directorio público.
const CFG_DB_DSN =
    'mysql:host=mysql.veryverifactu.com;dbname=webservicevvf;charset=utf8mb4';
const CFG_DB_USUARIO = 'adminvvf';
const CFG_DB_PASSWORD = 'JMk6jbeFC#5';

// La aplicación Delphi muestra ambos valores. Se registra la pública una vez.
const CFG_CLAVES_EMISORAS = [
    '3bab10ebbe08e01f' => 'ku5Dx81Hou0Frd4f1ijMV_XLqixXsMnAUpj-gTd3CzU'
];

const CFG_AMBITOS_PERMITIDOS = [
    'prueba:leer',
    'ventas:leer',
    'ventas:escribir',
    'fotos:leer',
    'fotos:escribir',
    'sif:instalacion',
    'recuentos:leer',
    'recuentos:escribir'
];

const CFG_DESFASE_MAXIMO_SEGUNDOS = 300;
const CFG_PREFIJO_TOKEN = 'fza_';
