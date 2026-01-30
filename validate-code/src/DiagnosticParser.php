<?php

declare(strict_types=1);

namespace Hooks;

class DiagnosticParser
{
    public function hasErrors(string $output): bool
    {
        return str_contains($output, 'Error [') || str_contains($output, 'Warning [');
    }

    public function extractDiagnostics(string $output): string
    {
        $lines = explode("\n", $output);
        $errorLines = [];
        $capture = false;

        foreach ($lines as $line) {
            if (str_contains($line, '===') && str_contains($line, 'Diagnostics')) {
                $capture = true;
            }
            if ($capture) {
                $errorLines[] = $line;
            }
        }

        return implode("\n", $errorLines);
    }
}
