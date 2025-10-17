<?php

namespace App\Services;

use App\Interfaces\AiServiceInterface;
use OpenAI\Laravel\Facades\OpenAI;

class OpenAiService implements AiServiceInterface
{
    public function generateAiCoverLetter(string $userPrompt): string
    {
         
    $systemPrompt = <<<PROMPT
        You are an experienced HR assistant specializing in crafting professional cover letters. Your task is to analyze the applicant's CV text and the provided job description, then generate a concise and persuasive 2-3 paragraph cover letter.
        
        Follow these constraints:
        - If the uploaded text does not appear to be a CV or contains irrelevant content, respond with: 
            The uploaded file does not seem to contain a valid CV. Please upload a proper CV document.
        - Use only the provided CV and Job Description to create the letter.
        - Do not fabricate or add any extra details not supported by the CV.
        - Do not mention that you are using AI or data sources.
        - Ensure tone is professional, confident, and tailored to the job.
        - Output only the cover letter text, 2-3 short paragraphs.
        PROMPT;

        $response = OpenAI::chat()->create([
            'model' => 'gpt-4o-mini',
            'messages' => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user', 'content' => $userPrompt],
            ],
        ]);

        return $response['choices'][0]['message']['content'] ?? 'No response generated.';
    }
} 