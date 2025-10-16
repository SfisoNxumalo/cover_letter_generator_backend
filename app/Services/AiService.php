<?php

namespace App\Services;

use App\Interfaces\AiServiceInterface;
use OpenAI\Laravel\Facades\OpenAI;

class AiService implements AiServiceInterface
{
    public function generateCoverLetter(string $cvText, string $jobDescription): string
    {
        $prompt = "Write a 2–3 paragraph cover letter explaining why this CV is ideal for the given job.\n\nCV:\n{$cvText}\n\nJob Description:\n{$jobDescription}";

        $response = OpenAI::chat()->create([
            'model' => 'gpt-4o-mini',
            'messages' => [
                ['role' => 'system', 'content' => 'You are an expert HR assistant.'],
                ['role' => 'user', 'content' => $prompt],
            ],
        ]);

        return $response['choices'][0]['message']['content'] ?? 'No response generated.';
    }
} 