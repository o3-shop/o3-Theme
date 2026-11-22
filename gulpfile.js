const { src, dest, series, parallel, watch } = require('gulp');
const esbuild = require('esbuild');
const sass = require('gulp-dart-sass');
const postcss = require('gulp-postcss');
const autoprefixer = require('autoprefixer');
const cleanCSS = require('gulp-clean-css');
const rename = require('gulp-rename');
const purgecss = require('@fullhuman/postcss-purgecss');
const { deleteAsync } = require('del');
const { globSync } = require('glob');
const path = require('path');

const theme = 'o3-theme';

const paths = {
    jsEntry: './build/js/main.bundle.js',
    scssEntry: './build/scss/main.bundle.scss',
    widgetJS: './build/js/widget/**/*.js',
    outDir: path.resolve(__dirname, 'out', theme, 'src'),
    tmpDir: '../../../tmp/**/*',
    watchPaths: {
        themeJS: './build/js/**/*.js',
        themeScss: './build/scss/**/*.scss',
        moduleJS: '../../../modules/**/out/src/js/**/*.js',
        moduleScss: '../../../modules/**/out/src/scss/**/*.scss',
        themeTpl: './tpl/**/*.tpl',
        themeTranslations: ['./de/**/*.php', './en/**/*.php'],
        moduleTpl: '../../../modules/**/Application/views/**/*.tpl',
        moduleTranslations: '../../../modules/**/Application/translations/**/*.php'
    }
};

// ─────────────────────────────────────────────
// Widget JS: Copy (für dev und prod)
function copyWidgetJS() {
    return src(paths.widgetJS)
        .pipe(dest(`${paths.outDir}/js/widget`))
        .on('end', () => {
            console.log('✅ Widget JS-Files kopiert');
        });
}

// Widget JS: Minify (nur für prod)
async function minifyWidgetJS() {
    try {
        const files = globSync(paths.widgetJS);

        if (files.length === 0) {
            throw new Error(`No widget JS files matched ${paths.widgetJS}`);
        }

        for (const file of files) {
            const relativePath = path.relative('./build/js/widget', file);
            const outputPath = path.join(`${paths.outDir}/js/widget`, relativePath.replace('.js', '.min.js'));

            await esbuild.build({
                entryPoints: [file],
                bundle: false,
                minify: true,
                sourcemap: false,
                outfile: outputPath,
                target: ['es2020'],
            });
        }
        console.log('✅ Widget JS-Files minifiziert');
    } catch (err) {
        console.error('❌ Fehler beim Minifizieren der Widget JS-Files:', err);
        throw err;
    }
}

// ─────────────────────────────────────────────
// PostCSS Plugins
// PurgeCSS is opt-in. The default production build ships the full, unpurged
// stylesheet: o3-theme is a base for child themes, modules and CMS content,
// which add classes at runtime that a static scan cannot see. A purged build
// silently drops those classes in productive mode (dev loads the unpurged
// main.css, so it still looks fine there). Enable with --purge or PURGE=1
// (see README).
const usePurge = process.env.PURGE === '1'
    || process.env.PURGE === 'true'
    || process.argv.includes('--purge');

const postcssDevPlugins = [autoprefixer()];
const postcssProdPlugins = [autoprefixer()];

if (usePurge) {
    postcssProdPlugins.push(
        purgecss({
            // Only the theme repo is scanned. The shop-relative ../../../modules/**
            // globs were removed: they resolve outside the repo in a standalone
            // build and to whatever modules happen to be installed in a shop, so
            // the committed main.min.css would depend on the build machine. A
            // module must ship the CSS it needs. See o3-shop/o3-shop#264.
            content: [
                './tpl/**/*.tpl',
                './build/js/**/*.js',
            ],
            safelist: [
                /^splide/, /^is-/, /^cl-/, /^mode__/, /backdrop/, /grid-view/, /line-view/, /btn-light/, /^video-container/
            ],
            defaultExtractor: content => content.match(/[\w-/:.]+(?<!:)/g) || [],
        })
    );
}

// ─────────────────────────────────────────────
// JS: Dev (.js + .map)
async function buildDevJS() {
    try {
        await esbuild.build({
            entryPoints: [paths.jsEntry],
            bundle: true,
            minify: false,
            sourcemap: true,
            outfile: `${paths.outDir}/js/main.js`,
            target: ['es2020'],
        });
        console.log('✅ main.js (dev) erstellt');
    } catch (err) {
        console.error('❌ Fehler bei main.js (dev):', err);
        throw err;
    }
}

// JS: Prod (.min.js)
async function buildProdJS() {
    try {
        await esbuild.build({
            entryPoints: [paths.jsEntry],
            bundle: true,
            minify: true,
            sourcemap: false,
            outfile: `${paths.outDir}/js/main.min.js`,
            target: ['es2020'],
        });
        console.log('✅ main.min.js (prod) erstellt');
    } catch (err) {
        console.error('❌ Fehler bei main.min.js (prod):', err);
        throw err;
    }
}

// ─────────────────────────────────────────────
// CSS: Dev (.css + .map)
function buildDevCSS() {
    return src(paths.scssEntry, { sourcemaps: true })
        .pipe(sass.sync({
            outputStyle: 'expanded'
        }).on('error', sass.logError))
        .pipe(postcss(postcssDevPlugins))
        .pipe(rename({ basename: 'main' }))
        .pipe(dest(`${paths.outDir}/css`, { sourcemaps: '.' }))
        .on('end', () => {
            console.log('✅ main.css (dev) mit Sourcemap erstellt');
        });
}

// CSS: Prod (.min.css + optional Purge)
function buildProdCSS() {
    return src(paths.scssEntry)
        .pipe(sass.sync().on('error', sass.logError))
        .pipe(postcss(postcssProdPlugins))
        .pipe(cleanCSS())
        .pipe(rename({ basename: 'main', suffix: '.min' }))
        .pipe(dest(`${paths.outDir}/css`))
        .on('end', () => {
            console.log(usePurge
                ? '✅ main.min.css (prod, mit PurgeCSS) erstellt'
                : '✅ main.min.css (prod, ohne PurgeCSS) erstellt');
        });
}

// ─────────────────────────────────────────────
// TMP leeren bei Template- oder Sprachänderung
async function cleanTmp() {
    try {
        await deleteAsync(paths.tmpDir, { force: true });
        console.log('🧹 tmp/ geleert wegen Template- oder Sprachänderung');
    } catch (err) {
        console.error('❌ Fehler beim Leeren von tmp/:', err);
        throw err;
    }
}

// ─────────────────────────────────────────────
// Watcher für DEV
function watchDev() {
    const { watchPaths } = paths;

    // Theme - JS
    watch(watchPaths.themeJS, async function() {
        console.log('🔄 Änderung in JS erkannt → baue main.js');
        await buildDevJS();
    });

    // Theme - SCSS
    watch(watchPaths.themeScss, async function() {
        console.log('🎨 Änderung in SCSS erkannt → baue main.css');
        await buildDevCSS();
    });

    // Theme - JS-Widget
    watch(paths.widgetJS, async function() {
        console.log('🔄 Änderung in Widget-JS erkannt → kopiere Widget-JS');
        await copyWidgetJS();
    });

    // Module - JS
    watch(watchPaths.moduleJS, async function() {
        console.log('🔄 Änderung in Modul-JS erkannt → baue main.js');
        await buildDevJS();
    });

    // Module - SCSS
    watch(watchPaths.moduleScss, async function() {
        console.log('🎨 Änderung in Modul-SCSS erkannt → baue main.css');
        await buildDevCSS();
    });

    // Templates & Translations
    watch(watchPaths.themeTpl, cleanTmp);
    watch(watchPaths.themeTranslations, cleanTmp);
    watch(watchPaths.moduleTpl, cleanTmp);
    watch(watchPaths.moduleTranslations, cleanTmp);
}

// ─────────────────────────────────────────────
// Task-Gruppen
exports.dev = series(
    parallel(buildDevJS, buildDevCSS, copyWidgetJS),
    watchDev
);

exports.prod = series(
    parallel(buildDevJS, buildProdJS, buildDevCSS, buildProdCSS, copyWidgetJS, minifyWidgetJS)
);

// Standard: Produktions-Build
exports.default = exports.prod;