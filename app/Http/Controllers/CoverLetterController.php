<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Smalot\PdfParser\Parser;
use OpenAI\Laravel\Facades\OpenAI;

class CoverLetterController extends Controller
{
    public function generate(Request $request)
    {
        
        $prompt = "Say hello like one";
        $response = OpenAI::chat()->create([
            'model' => 'gpt-5',
            'messages' => [
                ['role' => 'system', 'content' => 'You are an expert HR assistant.'],
                ['role' => 'user', 'content' => $prompt],
            ],
        ]);

        return response()->json([
            'coverLetter' => trim($response->choices[0]->message->content),
        ]);
    }
}
