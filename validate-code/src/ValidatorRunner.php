<?php

declare(strict_types=1);

namespace Hooks;

class ValidatorRunner
{
    private Logger $logger;

    public function __construct(Logger $logger)
    {
        $this->logger = $logger;
    }

    public function run(string $checkBat, string $filePath, string $projectDir): ValidatorResult
    {
        $command = sprintf('"%s" "%s" "%s"', $checkBat, $filePath, $projectDir);
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
