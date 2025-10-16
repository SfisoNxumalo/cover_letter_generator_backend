<?php

namespace App\Services;

use App\Interfaces\PdfParserInterface;
use Smalot\PdfParser\Parser;

class PdfParserService implements PdfParserInterface
{
    protected Parser $parser;

    public function __construct(Parser $parser)
    {
        $this->parser = $parser;
    }

    public function extractText(string $filePath): string
    {
        $pdf = $this->parser->parseFile($filePath);
        return $pdf->getText();
    }
}