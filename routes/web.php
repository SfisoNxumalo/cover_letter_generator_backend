<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CoverLetterController;

Route::get('/', function () {
    return view('welcome');
});
