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
 * Not reported: outputs with |raw, and outputs whose first filter is length/format_price/…/add_url_parameters or
 * |escape (|e) — the explicit marker for a `.value` that is not a core-escaped Field (raw DB/array values).
 * Output: "escape: <file>:<line>: <expression>", exit 1 on findings, else "OK <n> files".
 *
 * The reverse mistake (Task 8 audit) is reported as "rawtext: <file>:<line>: <expression>": an output with |raw whose
 * value is unescaped text, i.e.
 *   - `.value` of a field the core stores T_RAW although it holds shop/customer text ($rawTextFields, from the models'
 *     _setFieldData and Order::finalizeOrder), or
 *   - `.getRawValue()` / `.rawValue` of any field except admin rich text ($richTextFields: CMS, long descriptions,
 *     link descriptions; printed raw as in 1.x),
 *   - or a variable {% set %} from one of those.
 * Print such values escaped (autoescape or an explicit |escape), in JS strings via |e('js').
 * Also "transraw: …": translate with arguments printed |raw (marks the whole lang text safe). Escape the lang text and
 * put the already-escaped argument in: translate({ ident: "X" })|e|replace({ '%s': escapedArg })|raw.
 *
 * Mails: email/html/** follows the same rules. email/plain/** is not autoescaped (core), and Email::setAltBody() decodes
 * one level of entities, so plain mails print values as they are: there any |e, |escape or |raw is reported
 * ("plain: <file>:<line>: <expression>"), as it would put entities into the text or claim escaping that never happens.
 *
 * Usage: php build/lint-twig.php [dir|file …]   (default scope: the areas converted so far; widen it per task)
 */

$scope = array_slice($argv, 1) ?: [
    'tpl/layout', 'tpl/widget', 'tpl/message', 'tpl/page/shop',
    'tpl/page/list', 'tpl/page/details', 'tpl/page/search', 'tpl/page/compare', 'tpl/page/recommendations',
    'tpl/page/review', 'tpl/page/privatesales', 'tpl/rdfa',
    'tpl/page/checkout', 'tpl/form', 'tpl/page/account', 'tpl/page/info', 'tpl/page/revocation', 'tpl/page/wishlist',
    'tpl/email',
];

$urlGetters = [
    // Core/ViewConfig.php
    'getSelfActionLink', 'getSelfLink', 'getSslSelfLink', 'getHomeLink', 'getLogoutLink', 'getHelpPageLink',
    'getBasketLink', 'getOrderLink', 'getPaymentLink', 'getExeOrderLink', 'getOrderConfirmLink', 'getAjaxLink',
    'getCurrentHomeDir', 'getBaseDir',
    // Application/Model (Article, Category, Content, Manufacturer, Vendor, RecommendationList, Actions)
    'getLink', 'getMainLink', 'getStdLink', 'getBaseStdLink', 'getBaseSeoLink', 'getToBasketLink', 'getBannerLink',
    // Application/Controller/FrontendController.php and list/details controllers
    'getCanonicalUrl', 'getBaseLink', 'getCatMoreUrl', 'getWidgetLink',
    // Application/Model/Order.php, Basket.php (values built from escaped fields / an `&amp;` config URL)
    'getShipmentTrackingUrl', 'getCardMessage',
];
$basketItemGetters = ['getTitle', 'getVarSelect'];
// T_RAW fields holding plain text (raw DB value, never core-escaped)
$rawTextFields = [
    'oxorderarticles__oxtitle', 'oxorderarticles__oxpersparam', 'oxorderarticles__oxerpstatus', // OrderArticle::_setFieldData
    'oxuserbasketitems__oxsellist', 'oxuserbasketitems__oxpersparam',                           // UserBasketItem::_setFieldData
];
// admin-entered rich text (T_RAW or read via getRawValue()), printed raw like 1.x
$richTextFields = ['oxlongdesc', 'oxcontent', 'oxurldesc'];

$getters = implode('|', $urlGetters);
// a value path: identifiers, dots, calls with simple args, ['key'] lookups
$path = '[A-Za-z_][\w]*(?:\.[A-Za-z_]\w*(?:\([^(){}]*\))?|\[[^\]]*\])*';
$encoded = '/^' . $path . '(?:\.value|\.link|\.(?:' . $getters . ')\([^(){}]*\))$/';
$isRawText = function (string $expr) use ($rawTextFields, $richTextFields): bool {
    foreach ($rawTextFields as $f) {
        if (preg_match('/\b' . $f . '\.value\b/', $expr)) {
            return true;
        }
    }
    preg_match_all('/__(\w+)\.(?:getRawValue\(\)|rawValue\b)/', $expr, $m);
    return (bool) array_diff($m[1], $richTextFields);
};

$base = dirname(__DIR__);
$findings = [];
$count = 0;
foreach ($scope as $dir) {
    $it = is_file("$base/$dir") ? [new SplFileInfo("$base/$dir")]
        : new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$base/$dir", FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if (substr($file, -10) !== '.html.twig') {
            continue;
        }
        $count++;
        $rel = substr((string) $file, strlen($base) + 1);
        $src = file_get_contents((string) $file);
        $src = preg_replace_callback('/\{#.*?#\}/s', fn ($m) => str_repeat("\n", substr_count($m[0], "\n")), $src);
        if (strpos($rel, 'tpl/email/plain/') === 0) {
            preg_match_all('/\{[{%]-?\s*(.*?)\s*-?[}%]\}/s', $src, $tags, PREG_OFFSET_CAPTURE);
            foreach ($tags[1] as [$expr, $offset]) {
                if (preg_match('/\|\s*(e|escape|raw)\b/', $expr)) {
                    $findings[] = 'plain: ' . $rel . ':' . (substr_count($src, "\n", 0, $offset) + 1) . ": $expr";
                }
            }
            continue;
        }

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
        $rawTainted = [];
        preg_match_all('/\{%-?\s*set\s+(\w+)\s*=\s*(.*?)\s*-?%\}/s', $src, $sets, PREG_SET_ORDER);
        foreach ($sets as [, $var, $expr]) {
            if ($isRawText($expr)) {
                $rawTainted[] = $var;
            }
            $first = trim(explode('|', $expr)[0]);
            if ($isEncoded($first) || preg_match('/#\{[^}]*\.value\}/', $expr)) {
                $tainted[] = $var;
            }
        }

        preg_match_all('/\{\{-?\s*(.*?)\s*-?\}\}/s', $src, $outs, PREG_OFFSET_CAPTURE);
        foreach ($outs[1] as [$expr, $offset]) {
            if (preg_match('/\|\s*raw\b/', $expr)) {
                $line = substr_count($src, "\n", 0, $offset) + 1;
                if ($isRawText($expr) || in_array(trim(explode('|', $expr)[0]), $rawTainted, true)) {
                    $findings[] = "rawtext: $rel:$line: {{ $expr }}";
                }
                if (preg_match('/translate\(\{[^}]*\bargs\s*:|\|\s*translate\(\s*[^)\s]/', $expr)) {
                    $findings[] = "transraw: $rel:$line: {{ $expr }}";
                }
                continue;
            }
            $parts = explode('|', $expr);
            $first = trim($parts[0]);
            $filters = implode('|', array_slice($parts, 1));
            if (preg_match('/^\s*(length|format_price|date_format|format_date|count|add_url_parameters|escape|e)\b/', $filters)) {
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
