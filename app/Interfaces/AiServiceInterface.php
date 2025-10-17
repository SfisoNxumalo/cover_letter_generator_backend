<?php

namespace App\Interfaces;

interface AiServiceInterface
{
    public function generateAiCoverLetter(string $prompt): string;
}