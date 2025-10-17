<?php

namespace App\Services;

use App\Interfaces\AiServiceInterface;
use App\Interfaces\PdfParserInterface;
use OpenAI\Laravel\Facades\OpenAI;

class CoverLetterService 
{
    protected PdfParserInterface $parser;
    protected AiServiceInterface $aiGenerator;

    public function __construct(PdfParserInterface $parser, AiServiceInterface $aiGenerator)
    {
        $this->parser = $parser;
        $this->aiGenerator = $aiGenerator;
    }

    public function generateCoverLetter(string $cvPath, string $jobDescription): string
    {
        $cvText = $this->parser->extractText($cvPath);

        // User-level prompt: what the AI actually responds to each time
        $prompt = <<<PROMPT
            Write a 2-3 paragraph cover letter explaining why this CV is ideal for the given job.

            CV:
            {$cvText}

            Job Description:
            {$jobDescription}
            PROMPT;

        return $this->aiGenerator->generateAiCoverLetter($prompt);
    }
} 