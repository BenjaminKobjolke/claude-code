<?php

declare(strict_types=1);

namespace Hooks;

readonly class ValidatorResult
{
    public function __construct(
        public string $output,
        public int $returnCode
    ) {
    }
}
