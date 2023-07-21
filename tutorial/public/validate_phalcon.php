<?php
define('BASE_PATH', dirname(__DIR__));
echo ("base path: " . BASE_PATH);
define('APP_PATH', BASE_PATH . '/app');
require_once BASE_PATH . '/vendor/autoload.php';
if (!extension_loaded('phalcon')) {
    die("Phalcon extension is not loaded. Please check if the extension is properly installed.");
}
// require_once 'vendor/autoload.php'; // Include the Composer autoloader
echo "Phalcon Version: " . Phalcon\Version::get();
