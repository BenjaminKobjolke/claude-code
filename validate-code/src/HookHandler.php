<?php

declare(strict_types=1);

namespace Hooks;

use BeyondCode\ClaudeHooks\Hooks\PostToolUse;

class HookHandler
{
    private Logger $logger;
    private ValidatorRegistry $registry;
    private ValidatorRunner $runner;
    private DiagnosticParser $parser;

    public function __construct(Logger $logger, ValidatorRegistry $registry)
    {
        $this->logger = $logger;
        $this->registry = $registry;
        $this->runner = new ValidatorRunner($logger);
        $this->parser = new DiagnosticParser();
    }

    public function handle(PostToolUse $hook): void
    {
        $toolName = $hook->toolName();
        $this->logger->log("Tool: {$toolName}");

        if (!in_array($toolName, ['Edit', 'Write'], true)) {
            $this->logger->log("Tool not Edit/Write, skipping");
            $hook->success();
            return;
        }

        $filePath = $hook->toolInput('file_path', '');
        $this->logger->log("FilePath: {$filePath}");

        $validator = $this->registry->getValidatorForFile($filePath);
        if ($validator === null) {
            $this->logger->log("No validator found for file, skipping");
            $hook->success();
            return;
        }

        $projectDir = getenv('CLAUDE_PROJECT_DIR') ?: dirname(__DIR__, 2);
        $this->logger->log("Project dir: {$projectDir}");

        $httpPort = $validator['http_port'] ?? null;
        $result = $this->runner->run($validator['check_bat'], $filePath, $projectDir, $httpPort);

        if ($this->parser->hasErrors($result->output)) {
            $diagnostics = $this->parser->extractDiagnostics($result->output);
            $this->logger->log("Found errors, blocking with diagnostics");
            $this->block("LSP errors detected - please fix:\n" . $diagnostics);
        }

        $this->logger->log("No errors found");
        $hook->success();
    }

    private function block(string $reason): never
    {
        $output = json_encode([
            'decision' => 'block',
            'reason' => $reason
        ]);

        $this->logger->log("JSON output: {$output}");
        echo $output;
        exit(0);
    }
}
