<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Interfaces\PdfParserInterface;
use App\Services\PdfParserService;
use App\Interfaces\AiGeneratorInterface;
use App\Services\CoverLetterService;
use Smalot\PdfParser\Parser;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //DI
        $this->app->bind(PdfParserInterface::class, function () {
            return new PdfParserService(new Parser());
        });

        $this->app->bind(AiGeneratorInterface::class, CoverLetterService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
