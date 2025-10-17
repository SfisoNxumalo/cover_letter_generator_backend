<?php

namespace App\Services;

use App\Interfaces\AiServiceInterface;
use OpenAI\Laravel\Facades\OpenAI;

class OpenAiService implements AiServiceInterface
{
    public function generateAiCoverLetter(string $prompt): string
    {

        
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