# Changelog

## [1.5.0] — 2026-06-19

### New Features / Overview
- 3xl-size, subcategory tiles, template fixes, CSS consolidation

### Changed
- `tpl/layout/header.tpl` — `blDisableNavBars` now hides search bar and burger icon in checkout steps after basket (user, payment, order); topinfo bar hidden in `is-minimal` mode to fix wrapping layout caused by `flex: 1 1 100%`
- `tpl/widget/footer/info.tpl` — Added Datenschutz (`oxsecurityinfo`) and Widerrufsrecht (`oxrightofwithdrawal`) CMS content links at top of footer information column; phone number display disabled
- `tpl/layout/base.tpl`
— Background image inline CSS and `has-bg-image` body class now gated on `!$smarty.get.plain` to prevent BG image rendering on plain-text pages; `[{block name="base_fonts"}]` block removed (was the `[{oxstyle include="css/custom.css"}]` call, no longer needed)
- `tpl/widget/locator/itemsperpage.tpl` — `getNrOfCatArticles()` result now assigned to a variable and null-checked before `|@count` to prevent rendering errors when the method returns null
- `tpl/widget/product/list_splide.tpl` — Reverted to `$products|@count` (Smarty modifier, safe for both arrays and objects); `->count()` caused fatal errors when `$products` is a plain array
- `tpl/widget/product/list.tpl` — Added `col-xxxl-fifth` CSS class to productbox div for 5-column layout at xxxl breakpoint
- `tpl/page/checkout/inc/steps.tpl` — Checkout step indicators (01/02/03) are now clickable links back to the respective step; inactive future steps remain non-interactive
- `tpl/page/list/list.tpl` — Subcategory tile grid mode: when `blShowSubcatTiles` is enabled, subcategories render as product-box-style tiles instead of pills; CMS content-category pills extracted to a separate block always shown above the grid
- `out/o3-theme/src/css/main.css` — All rules previously in `custom.css` (which was loaded as a separate HTTP request via `[{oxstyle include="css/custom.css"}]`) are now merged into `main.css` under a `/* ── custom overrides ── */` block at the end of the file. `custom.css` has been removed.
- `out/o3-theme/src/css/main.min.css` — Regenerated from updated `main.css`
- `theme.php` — Version bumped to 1.5; added `blShowSubcatTiles` (bool, default off) to the `display` settings group

### Added
- `tpl/widget/product/listitem_infogrid.tpl` — New shim template forwarding the `infogrid` display type to `listitem_grid.tpl`; previously absent from vendor, causing template-not-found errors

### CSS overrides added to main.css (v1.5)
- `:root { --accent-color }` default
- Header search button background, topinfo and mainnav margin/padding bleed
- `.start__manufacturer` background and padding
- Video container responsive embed helper
- `.details__variants` bottom margin
- `.component__tobasket[data-tooltip]` submit opacity
- `.component__productbox-title` height override
- `.splide__pagination__page` colors
- `.component__password-bar ~ .bg-light` background
- `.alert-info`, `.alert-warning` background and border
- `#cookieNoteClose` button reset styles
- `.component__tobasket-minus:disabled` and `.component__tobasket-plus:disabled` SVG stroke darkened to `#888888` for contrast

---

## [1.4.2] — upstream

See <https://github.com/o3-shop/o3-Theme/releases/tag/v1.4.2>
