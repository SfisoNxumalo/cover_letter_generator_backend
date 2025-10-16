<?php

namespace App\Interfaces;

interface AiServiceInterface
{
    public function generateCoverLetter(string $cvText, string $jobDescription): string;
}