# Changelog

## [2.0.0] — Unreleased

### Changed
- **Twig port.** All storefront templates (including e-mails) are now Twig (`tpl/**/*.html.twig`); the Smarty `.tpl` files are removed. Requires shop-ce 2.x (`o3-shop/shop-ce: ^2.0`). Theme id, package name and block names are unchanged. For the upgrade from 1.x and the rules for module/theme authors see `docs/twig.md` in shop-ce.
- Initial conversion is the automated `smarty-to-twig-converter` baseline; templates are reworked by hand in follow-up commits.
- **Page layout via inheritance (forced block change).** Pages `{% extends "layout/page.html.twig" %}` and fill the new block `content` (inside `content_main`) instead of `[{capture append="oxidBlock_content"}]` + `[{include file="layout/page.tpl"}]`. `content` is the only block without a 1.x counterpart; its default still prints `oxidBlock_content`. Variables the layout reads (`blHideBreadcrumb`) are set at the page's top level. See the comment at the top of `tpl/layout/page.html.twig`.
- `layout/header.html.twig`: `dd_layout_page_header_icon_menu_languages` and `dd_layout_page_header_icon_menu_currencies` were defined twice in 1.x (top bar and off-canvas menu); Twig allows one definition per name, so the off-canvas menu renders them with `{{ block('…') }}`. An override of either block still applies to both places.
- `page/details/inc/tabs.html.twig`: a Twig block only gets a copy of the context, so the 1.x pattern (each `details_tabs_*` block appends to the `tabs`/`tabsContent` captures, `details_tabs_main` prints them) cannot work. Each tab block now prints its nav link when `tabPart == 'nav'` and its pane when `tabPart == 'content'`; the template renders every tab block twice (1.x order: first with `tabPart == 'nav'`, then, if that printed anything, with `tabPart == 'content'`) and passes the results to `details_tabs_main`. All output and side effects of a tab block (includes, widgets, `script()`) must therefore be gated by `tabPart`; one block yields at most one tab. The block definitions sit inside `{% if false %}` so they are not also rendered where they are defined; they stay overridable. `blFirstTab` is true for the first visible tab. A module adds a tab by overriding one of the empty tab blocks the same way. `details_tabs_pricealarm` now checks `bl_showPriceAlarm` itself (1.x wrapped the block in that check).
- `page/details/inc/productmain.html.twig`: `blCanBuy` is computed before the blocks instead of inside `details_productmain_variantselections` (same logic; a block cannot change the variable `details_productmain_tobasket` reads).
- Long descriptions (`details_tabs_longdescription`, category description on the list page) are printed from `getLongDesc()` (CMS text rendered through Smarty by the core, as `[{oxeval}]` did) instead of being evaluated in the template.
- `page/details/details.html.twig` and `page/privatesales/invite.html.twig` keep the 1.x `capture append` + include shape (details is also included as a partial by `widget/product/details`; invite prints the cookie-note widget before the page).
- `form/fieldset/user_shipping.html.twig`: `form_user_shipping_country` was defined three times in 1.x with different bodies (edit form of the selected address, form for a new address, form when the user has no address). Twig allows one definition per name, so it is defined once and rendered with `{{ block('form_user_shipping_country') }}` at the other two places; `sShippingCountryForm` names the variant (unset = edit, `'new'`, `'register'`). An override of the block applies to all three places, as in 1.x; check `sShippingCountryForm` to keep the variants apart.
- Checkout pages (`order`, `payment`): variables 1.x assigned inside one block and read in a sibling block (`currency`, `payment`) are set at the start of the page's `content` block, because a Twig block only gets a copy of the context.
- `page/checkout/inc/basketcontents_list.html.twig`: the unit name after the amount stepper is gone. 1.x printed `$basketitem->oxarticles__oxunitname->value`, which a basket item never has (always empty); in Twig the access would reach `BasketItem::__call` and throw.

## [Unreleased]

### Added
- Search suggest dropdown in the header search (`tpl/widget/header/search.tpl`, `build/js/widget/oxsearchsuggest.js`, `build/scss/widget/header/_search.scss`) — debounced JSON lookup against the `searchsuggest` controller, keyboard-navigable result list with thumbnail, title and price. Requires shop-ce with the `searchsuggest` endpoint (shop-ce#219); the form degrades to a plain search submit on older shops, when the suggest endpoint is disabled and without JavaScript.

### Fixed
- Remove overly narrow `pattern` from password fields in `forgotpwd_change_pwd.tpl` and `user_password.tpl`; the HTML5 pattern only allowed 7 special characters (`@$!%*?&`) while `validate.js` accepts 29, causing valid passwords to be rejected at submit and the confirm field to falsely show "passwords do not match" (#225)
- `forgotpwd_change_pwd.tpl` still referenced the lang ident `O3_FORM_VALIDATION_PASSWORD_LETTERS`, which was split into four separate idents (`..._UPPERCASE_LETTER`, `..._LOWERCASE_LETTER`, `..._NUMBER`, `..._SPECIAL_CHARACTER`) when the password strength meter was added, so resetting a password via the "Forgot password" email link rendered `Translation for O3_FORM_VALIDATION_PASSWORD_LETTERS not found!`. The template now includes the shared `form/fieldset/password_validation.tpl` fieldset, same as `user_password.tpl`, bringing the password reset page the live strength meter/requirement checklist instead of the stale static hint text.

---

## [1.6.0] — 2026-07-16

### Added
- EU guarantee labels (#219) — shop-global legal-guarantee notice (footer) and producer durability-guarantee label (product page, order page, order email). Requires shop-ce with #219 core (graceful no-op on older shops).

---

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
