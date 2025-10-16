<?php

namespace App\Interfaces;

interface PdfParserInterface
{
    public function extractText(string $filePath): string;
}