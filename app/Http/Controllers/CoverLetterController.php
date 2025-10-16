<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Smalot\PdfParser\Parser;
use OpenAI\Laravel\Facades\OpenAI;

class CoverLetterController extends Controller
{
    protected PdfParserInterface $pdfParser;
    protected AiGeneratorInterface $aiGenerator;

    public function __construct(PdfParserInterface $pdfParser, AiGeneratorInterface $aiGenerator)
    {
        $this->pdfParser = $pdfParser;
        $this->aiGenerator = $aiGenerator;
    }

    public function generate(Request $request)
    {
        $validated = $request->validate([
            'cv' => 'required|file|mimes:pdf|max:2048',
            'jobDescription' => 'required|string',
        ]);

        $cvText = $this->pdfParser->extractText($request->file('cv')->getRealPath());

        $coverLetter = $this->aiGenerator->generateCoverLetter(
            $cvText,
            $validated['jobDescription']
        );

        return response()->json(['coverLetter' => $coverLetter]);
    }
}
