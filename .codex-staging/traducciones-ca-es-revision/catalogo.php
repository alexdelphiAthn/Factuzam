<?php
declare(strict_types=1);

return [
    'en-GB' => [
        'nombre' => 'Inglés británico',
        'version' => 1,
        'archivos' => [
            '000_preparar_descarga.sql',
            '001_catalogo_completo.sql'
        ]
    ],
    'ca-ES' => [
        'nombre' => 'Catalán',
        'version' => 2,
        'archivos' => [
            '000_preparar_descarga.sql',
            '001_catalogo_completo.sql',
            '002_revision_linguistica.sql'
        ]
    ],
    'zh-CN' => [
        'nombre' => 'Chino simplificado',
        'version' => 4,
        'archivos' => [
            '000_preparar_descarga.sql',
            '001_menu_principal.sql',
            '002_catalogo_completo.sql',
            '003_ajustes_interfaz_caja.sql'
        ]
    ]
];
