<?php

/**
 * Block-name parity: every Smarty [{block name="X"}] in the .tpl files of <ref> must exist
 * as {% block X %} in the matching .html.twig under <dir>.
 *
 * Usage: php build/check-block-parity.php <ref-with-tpl> <dir-with-twig>
 *   e.g. php build/check-block-parity.php main .
 * Exit 0 + "OK <n> blocks", else "missing: <file>: <block>" lines and exit 1.
 */

[, $ref, $dir] = $argv + [null, 'main', '.'];
$git = 'git -C ' . escapeshellarg($dir);

$files = array_filter(explode("\n", (string) shell_exec("$git ls-tree -r --name-only " . escapeshellarg($ref) . ' -- tpl')));
$total = 0;
$missing = [];

foreach ($files as $file) {
    if (substr($file, -4) !== '.tpl') {
        continue;
    }
    $tpl = (string) shell_exec("$git show " . escapeshellarg("$ref:$file"));
    // name may be double/single quoted, with other attributes before or after
    preg_match_all('/\[\{\s*block\b[^}]*?\bname\s*=\s*(["\'])(.*?)\1/s', $tpl, $m);
    $blocks = array_unique($m[2]);
    $total += count($blocks);

    $twigFile = rtrim($dir, '/') . '/' . substr($file, 0, -4) . '.html.twig';
    $twig = is_file($twigFile) ? file_get_contents($twigFile) : '';
    foreach ($blocks as $block) {
        if (!preg_match('/\{%-?\s*block\s+' . preg_quote($block, '/') . '\b/', $twig)) {
            $missing[] = "missing: $file: $block";
        }
    }
}

if ($missing) {
    echo implode("\n", $missing), "\n";
    exit(1);
}
echo "OK $total blocks\n";
