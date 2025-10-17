<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\CoverLetterService;


class CoverLetterController extends Controller
{
    protected CoverLetterService $coverLetterService;

    public function __construct(CoverLetterService $coverLetterService)
    {
        $this->coverLetterService = $coverLetterService;
    }

    /**
     * This is the controller that handles our request 
     * and calls the service which contains the business logic
     */
    public function generate(Request $request)
    {
        $validated = $request->validate([
            'cv' => 'required|file|mimes:pdf|max:2048',
            'jobDescription' => 'required|string',
        ]);

        $cvPath = $request->file('cv')->getRealPath();
        $jobDescription = $request->jobDescription;

        $coverLetter = $this->coverLetterService->generateCoverLetter($cvPath, $jobDescription);

        return response()->json(['coverLetter' => $coverLetter]);
    }
}
