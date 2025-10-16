<?php

namespace App\Interfaces;

interface AiGeneratorInterface
{
    public function generateCoverLetter(string $cvText, string $jobDescription): string;
}