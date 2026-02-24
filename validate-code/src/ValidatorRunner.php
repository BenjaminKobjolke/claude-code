<?php

declare(strict_types=1);

namespace Hooks;

class ValidatorRunner
{
    private const FALLBACK_TIMEOUT = 10;

    private Logger $logger;

    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }

    /**
     * Run diagnostics via MCP HTTP endpoint, falling back to check.bat.
     */
    public function run(string $checkBat, string $filePath, string $projectDir, ?int $httpPort = null): ValidatorResult
    {
        if ($httpPort !== null) {
            $result = $this->runViaHttp($httpPort, $filePath, $projectDir);
            if ($result !== null) {
                return $result;
            }
            $this->logger->log("HTTP endpoint failed, falling back to check.bat with timeout");
        }

        return $this->runViaBat($checkBat, $filePath, $projectDir);
    }

    private function runViaHttp(int $port, string $filePath, string $projectDir): ?ValidatorResult
    {
        $url = "http://127.0.0.1:{$port}/diagnostics";
        $payload = json_encode([
            'project_path' => $projectDir,
            'file_path' => $filePath,
            'min_severity' => 'warning',
        ]);

        $this->logger->log("Trying HTTP endpoint: {$url}");

        $context = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => "Content-Type: application/json\r\n",
                'content' => $payload,
                'timeout' => 30,
            ],
        ]);

        $response = @file_get_contents($url, false, $context);

        if ($response === false) {
            $this->logger->log("HTTP request failed (MCP server not running?)");
            return null;
        }

        $data = json_decode($response, true);
        if (!is_array($data)) {
            $this->logger->log("HTTP response not valid JSON");
            return null;
        }

        $this->logger->log("HTTP response received, has_errors=" . ($data['has_errors'] ? 'true' : 'false')
            . ", has_warnings=" . ($data['has_warnings'] ? 'true' : 'false'));

        $output = $data['output'] ?? '';

        // Map HTTP response to the same format check.bat produces
        // DiagnosticParser looks for "Error [" and "Warning [" patterns
        // The MCP HTTP endpoint returns "[error]" and "[warning]" in lowercase
        // Normalize to match what DiagnosticParser expects
        $normalizedOutput = str_replace(['[error]', '[warning]'], ['Error [', 'Warning ['], $output);

        $returnCode = ($data['has_errors'] || $data['has_warnings']) ? 1 : 0;

        return new ValidatorResult($normalizedOutput, $returnCode);
    }

    private function runViaBat(string $checkBat, string $filePath, string $projectDir): ValidatorResult
    {
        $command = sprintf(
            '"%s" "%s" "%s" --timeout %d',
            $checkBat,
            $filePath,
            $projectDir,
            self::FALLBACK_TIMEOUT
        );
        $this->logger->log("Running command: {$command}");

        $outputLines = [];
        $returnCode = 0;
        exec($command . ' 2>&1', $outputLines, $returnCode);
        $output = implode("\n", $outputLines);

        $this->logger->log("Return code: {$returnCode}");
        $this->logger->log("Output: {$output}");

        return new ValidatorResult($output, $returnCode);
    }
}
