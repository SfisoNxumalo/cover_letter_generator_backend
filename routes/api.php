<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CoverLetterController;

Route::post('/v1/generate', [CoverLetterController::class, 'generate']);
