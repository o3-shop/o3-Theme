<?php

/**
 * Escaping lint for the Twig port (controller rulings T3/T4).
 *
 * Under autoescape, values the core hands out already HTML-encoded must be printed with |raw, or they come out
 * double-encoded (`&amp;amp;`). Reports every {{ … }} output without |raw whose value is
 *   - a model field `.value` (T_TEXT fields are htmlspecialchars-ed by the core, Field::__get),
 *   - a core URL getter returning `&amp;`-encoded URLs (list below, taken from the core's get*Link/Url/Dir methods
 *     that build URLs with UtilsUrl / `&amp;`), or a `.link` property built by them (languages, breadcrumb, RSS),
 *   - BasketItem::getTitle()/getVarSelect() (they return field `.value`s) on a loop variable over `….getContents()`
 *     (other getTitle()s, e.g. Attribute::getTitle(), return raw DB text and must stay escaped),
 *   - a variable {% set %} from one of the above in the same file (also via "#{…}" interpolation).
 * Output: "escape: <file>:<line>: <expression>", exit 1 on findings, else "OK <n> files".
 *
 * Usage: php build/lint-twig.php [dir …]   (default scope: the areas converted so far; widen it per task)
 */

$scope = array_slice($argv, 1) ?: ['tpl/layout', 'tpl/widget', 'tpl/message', 'tpl/page/shop'];

$urlGetters = [
    // Core/ViewConfig.php
    'getSelfActionLink', 'getSelfLink', 'getSslSelfLink', 'getHomeLink', 'getLogoutLink', 'getHelpPageLink',
    'getBasketLink', 'getOrderLink', 'getPaymentLink', 'getExeOrderLink', 'getOrderConfirmLink', 'getAjaxLink',
    'getCurrentHomeDir', 'getBaseDir',
    // Application/Model (Article, Category, Content, Manufacturer, Vendor, RecommendationList, Actions)
    'getLink', 'getMainLink', 'getStdLink', 'getBaseStdLink', 'getBaseSeoLink', 'getToBasketLink', 'getBannerLink',
    // Application/Controller/FrontendController.php and list/details controllers
    'getCanonicalUrl', 'getBaseLink', 'getCatMoreUrl', 'getWidgetLink',
];
$basketItemGetters = ['getTitle', 'getVarSelect'];

$getters = implode('|', $urlGetters);
// a value path: identifiers, dots, calls with simple args, ['key'] lookups
$path = '[A-Za-z_][\w]*(?:\.[A-Za-z_]\w*(?:\([^(){}]*\))?|\[[^\]]*\])*';
$encoded = '/^' . $path . '(?:\.value|\.link|\.(?:' . $getters . ')\([^(){}]*\))$/';

$base = dirname(__DIR__);
$findings = [];
$count = 0;
foreach ($scope as $dir) {
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$base/$dir", FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if (substr($file, -10) !== '.html.twig') {
            continue;
        }
        $count++;
        $rel = substr((string) $file, strlen($base) + 1);
        $src = file_get_contents((string) $file);
        $src = preg_replace_callback('/\{#.*?#\}/s', fn ($m) => str_repeat("\n", substr_count($m[0], "\n")), $src);

        // basket items: {% for x in ….getContents() %} → x.getTitle()/getVarSelect() are encoded
        preg_match_all('/\{%-?\s*for\s+(?:\w+\s*,\s*)?(\w+)\s+in\s+[\w.()]*getContents\(\)/', $src, $loops);
        $basketVars = $loops[1];
        $isEncoded = function (string $first) use ($encoded, $basketVars, $basketItemGetters): bool {
            if (preg_match($encoded, $first)) {
                return true;
            }
            return (bool) preg_match('/^(' . implode('|', $basketVars ?: ['(?!)']) . ')\.(' . implode('|', $basketItemGetters) . ')\(\)$/', $first);
        };

        // variables set from an encoded value
        $tainted = [];
        preg_match_all('/\{%-?\s*set\s+(\w+)\s*=\s*(.*?)\s*-?%\}/s', $src, $sets, PREG_SET_ORDER);
        foreach ($sets as [, $var, $expr]) {
            $first = trim(explode('|', $expr)[0]);
            if ($isEncoded($first) || preg_match('/#\{[^}]*\.value\}/', $expr)) {
                $tainted[] = $var;
            }
        }

        preg_match_all('/\{\{-?\s*(.*?)\s*-?\}\}/s', $src, $outs, PREG_OFFSET_CAPTURE);
        foreach ($outs[1] as [$expr, $offset]) {
            if (preg_match('/\|\s*raw\b/', $expr)) {
                continue;
            }
            $parts = explode('|', $expr);
            $first = trim($parts[0]);
            $filters = implode('|', array_slice($parts, 1));
            if (preg_match('/^\s*(length|format_price|date_format|format_date|count|add_url_parameters)\b/', $filters)) {
                continue;
            }
            if ($isEncoded($first) || in_array($first, $tainted, true)) {
                $line = substr_count($src, "\n", 0, $offset) + 1;
                $findings[] = "escape: $rel:$line: {{ $expr }}";
            }
        }
    }
}

if ($findings) {
    echo implode("\n", $findings), "\n";
    exit(1);
}
echo "OK $count files\n";
