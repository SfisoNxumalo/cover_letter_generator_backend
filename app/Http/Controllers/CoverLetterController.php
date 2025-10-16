<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Smalot\PdfParser\Parser;
use OpenAI\Laravel\Facades\OpenAI;

class CoverLetterController extends Controller
{
    public function generate(Request $request)
    {
        $request->validate([
            'cv' => 'required|file|mimes:pdf|max:2048',
            'jobDescription' => 'required|string',
        ]);

        // Extract text from the uploaded PDF
        $parser = new Parser();
        $pdf = $parser->parseFile($request->file('cv')->getRealPath());
        $cvText = $pdf->getText();

        // Generate cover letter using GPT
        $prompt = "Write a 2-3 paragraph cover letter explaining why this CV is ideal for the given job.\n\nCV:\n{$cvText}\n\nJob Description:\n{$request->jobDescription}";

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
