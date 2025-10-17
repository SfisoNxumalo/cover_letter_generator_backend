<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Interfaces\PdfParserInterface;
use App\Services\PdfParserService;
use App\Interfaces\AiServiceInterface;
use App\Services\OpenAiService;
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
        $this->app->bind(PdfParserInterface::class, PdfParserService::class);
        $this->app->bind(AiServiceInterface::class, OpenAiService::class);
        $this->app->bind(CoverLetterService::class, function ($app) {
            return new CoverLetterService(
                $app->make(PdfParserInterface::class),
                $app->make(AiServiceInterface::class)
            );
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
