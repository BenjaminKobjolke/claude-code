<?php

declare(strict_types=1);

namespace Hooks;

class ValidatorRegistry
{
    /** @var array<string, array{check_bat: string, extensions: string[], exclude_paths: string[]}> */
    private array $validators;

    /**
     * @param array<string, array{check_bat: string, extensions: string[], exclude_paths: string[]}> $validators
     */
    public function __construct(array $validators)
    {
        $this->validators = $validators;
    }

    /**
     * Get validator config for a file based on its extension.
     *
     * @return array{check_bat: string, extensions: string[], exclude_paths: string[]}|null
     */
    public function getValidatorForFile(string $filePath): ?array
    {
        foreach ($this->validators as $validator) {
            foreach ($validator['extensions'] as $extension) {
                if (str_ends_with($filePath, $extension)) {
                    if ($this->shouldExclude($filePath, $validator['exclude_paths'])) {
                        return null;
                    }
                    return $validator;
                }
            }
        }

        return null;
    }

    /**
     * @param string[] $excludePaths
     */
    private function shouldExclude(string $filePath, array $excludePaths): bool
    {
        foreach ($excludePaths as $excludePath) {
            if (str_contains($filePath, DIRECTORY_SEPARATOR . $excludePath . DIRECTORY_SEPARATOR)) {
                return true;
            }
        }

        return false;
    }
}
