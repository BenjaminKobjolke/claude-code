<?php

/**
 * Example configuration for validate-code hook.
 *
 * Copy this file to config.php and adjust the paths for your system.
 */

return [
    'validators' => [
        'php' => [
            'check_bat' => 'D:\\GIT\\BenjaminKobjolke\\intelephense-mpc-windows\\check.bat',
            'extensions' => ['.php'],
            'exclude_paths' => ['hooks'],
        ],
        'dart' => [
            'check_bat' => 'D:\\GIT\\BenjaminKobjolke\\dart-lsp-mcp\\check.bat',
            'extensions' => ['.dart'],
            'exclude_paths' => [],
        ],
    ],
];
