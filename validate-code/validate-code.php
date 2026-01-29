<?php

require __DIR__ . '/vendor/autoload.php';

use BeyondCode\ClaudeHooks\ClaudeHook;
use BeyondCode\ClaudeHooks\Hooks\PostToolUse;
use Hooks\HookHandler;
use Hooks\Logger;
use Hooks\ValidatorRegistry;

$hook = ClaudeHook::create();

if (!$hook instanceof PostToolUse) {
    $hook->success();
}

/** @var PostToolUse $hook */

$configPath = __DIR__ . '/config.php';
if (!file_exists($configPath)) {
    echo json_encode([
        'decision' => 'block',
        'reason' => "Validator config not found. Please copy config_example.php to config.php and configure your validator paths:\n"
            . "  cp " . __DIR__ . "/config_example.php " . $configPath
    ]);
    exit(0);
}

$config = require $configPath;
$logger = new Logger(__DIR__ . '/logs');
$registry = new ValidatorRegistry($config['validators']);
$handler = new HookHandler($logger, $registry);

$handler->handle($hook);
