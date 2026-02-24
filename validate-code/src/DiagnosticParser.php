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

        // If no "=== Diagnostics ===" header found (HTTP endpoint format),
        // return the full output since it already contains only diagnostics
        if ($errorLines === []) {
            return trim($output);
        }

        return implode("\n", $errorLines);
    }
}
