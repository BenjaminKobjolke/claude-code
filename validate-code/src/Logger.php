<?php

declare(strict_types=1);

namespace Hooks;

class Logger
{
    private string $logDir;
    private int $retentionDays;

    public function __construct(string $logDir, int $retentionDays = 5)
    {
        $this->logDir = $logDir;
        $this->retentionDays = $retentionDays;

        if (!is_dir($this->logDir)) {
            mkdir($this->logDir, 0755, true);
        }
    }

    public function log(string $message): void
    {
        $logFile = $this->getLogFilePath();
        $timestamp = date('Y-m-d H:i:s');
        $formattedMessage = "[{$timestamp}] {$message}\n";

        file_put_contents($logFile, $formattedMessage, FILE_APPEND);

        $this->cleanOldLogs();
    }

    private function getLogFilePath(): string
    {
        $date = date('Y-m-d');
        return $this->logDir . DIRECTORY_SEPARATOR . $date . '.log';
    }

    private function cleanOldLogs(): void
    {
        $files = glob($this->logDir . DIRECTORY_SEPARATOR . '*.log');
        if ($files === false) {
            return;
        }

        $cutoffTime = strtotime("-{$this->retentionDays} days");

        foreach ($files as $file) {
            $filename = basename($file, '.log');
            $fileDate = strtotime($filename);

            if ($fileDate !== false && $fileDate < $cutoffTime) {
                unlink($file);
            }
        }
    }
}
