<?php

/**
 * Compile check: tokenizes and parses (does not render) every tpl/**\/*.html.twig with the shop's Twig environment
 * (the one behind oxid_esales.templating.twig_engine, with all shop extensions/tags/filters registered), so
 * syntax errors and unknown tags, filters or functions fail here instead of on the first page view.
 * Runs inside the shop container (bootstraps the shop):
 *   docker exec -w /var/www/html/source/Application/views/o3-theme o3shop-shop-ce-shop-1 php build/compile-twig.php
 * Output: "compile: <file>: <error>" per broken template and exit 1, else "OK <n> files".
 */

use OxidEsales\EshopCommunity\Internal\Container\ContainerFactory;
use Twig\Error\Error;
use Twig\Source;

require __DIR__ . '/../../../../bootstrap.php';

$engine = ContainerFactory::getInstance()->getContainer()->get('oxid_esales.templating.twig_engine');
// TwigEngine has no accessor for its Environment; the "twig" service is private, and the engine's constructor is
// what registers the shop's extensions on it.
$twig = (fn () => $this->engine)->call($engine);

$dir = dirname(__DIR__) . '/tpl';
$files = new RegexIterator(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir)), '/\.html\.twig$/');
$count = 0;
$failed = false;
foreach ($files as $file) {
    $name = substr($file->getPathname(), strlen($dir) + 1);
    $count++;
    try {
        $twig->parse($twig->tokenize(new Source(file_get_contents($file->getPathname()), $name, $file->getPathname())));
    } catch (Error $e) {
        echo "compile: tpl/$name: " . $e->getMessage() . "\n";
        $failed = true;
    }
}

echo $failed ? '' : "OK $count files\n";
exit($failed ? 1 : 0);
