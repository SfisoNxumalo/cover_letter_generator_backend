<?php

return [
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => ['http://localhost:3000'], // React dev server
'allowed_headers' => ['*'],
'supports_credentials' => false,
];