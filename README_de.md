
# O3 Theme

## 1. General Information

**O3 Theme** is a responsive theme for all O3 Shop editions.

### Key Features
- Bootstrap 5.3.8
- Custom build process (Gulp)
- Optional PurgeCSS (standardmäßig deaktiviert)
- SplideJS for sliders

### O3-Theme 2.x (Twig)

O3-Theme 2.x ist ein **Twig**-Theme (`'templateEngine' => 'twig'` in `theme.php`) und
setzt **O3-Shop 2.0** voraus (`o3-shop/shop-ce: ^2.0`). Es liegt auf dem Branch `b-2.0`.
Die Smarty-Linie, O3-Theme 1.x, bleibt auf `main` für O3-Shop-1.x-Shops und für 2.0-Shops,
die eine Smarty-Storefront behalten. Offener Punkt: Die veröffentlichten 1.x-Tags verlangen
`o3-shop/shop-ce: ^1.2`, daher kann Composer sie noch nicht neben O3-Shop 2.0 installieren;
dafür braucht es ein O3-Theme-1.x-Release, dessen `composer.json` auch shop-ce 2.0 erlaubt
(noch nicht veröffentlicht). Bis dahin den Theme-Checkout bzw. das Paket manuell auf der
1.x-Linie halten. Regeln für Template-, Modul- und Child-Theme-Autoren: `docs/twig.md` in shop-ce.
Ein Child-Theme von O3-Theme 2.x muss ebenfalls ein Twig-Theme sein.

## 2. Installation
Das Theme wird mit dem o3-Shop System ausgeliefert und muss nicht installiert werden.

## 3. Update
Das Theme wird mit dem o3-Shop System mit jedem neuen Release aktualisiert.

## 4. Entwicklung

**Verwenden Sie diese Methode, wenn:** Sie das Thema anpassen oder neue Funktionen entwickeln möchten.

| Requirement | Minimum Version | Notes |
|------------|----------------|-------|
| Node.js | v22.13.0 | [Download](https://nodejs.org/) |
| npm | 10.x | Included with Node.js |
| Gulp CLI | 3.0.0 | [Download](https://gulpjs.com/) |

#### Build-Dateien für bestehendes Theme kopieren
```bash
cp -r <DOCUMENT_ROOT>/vendor/o3-shop/o3-theme/build <DOCUMENT_ROOT>/source/Application/views/<THEME_NAME>
cp -r <DOCUMENT_ROOT>/vendor/o3-shop/o3-theme/package.json <DOCUMENT_ROOT>/source/Application/views/<THEME_NAME>
```
#### Erstellung eines Child-Themes

1. Views Ordner anlegen und Dateien kopieren

```bash
mkdir <DOCUMENT_ROOT>/source/Application/views/<THEME_NAME>
cp -r <DOCUMENT_ROOT>/vendor/o3-shop/o3-theme/* <DOCUMENT_ROOT>/source/Application/views/<THEME_NAME>
```

2. Out Ordner <THEME_NAME> anlegen und Dateien kopieren

```bash
mkdir <DOCUMENT_ROOT>/source/out/<THEME_NAME>
cp -r <DOCUMENT_ROOT>/vendor/o3-shop/o3-theme/out/o3-theme* <DOCUMENT_ROOT>/source/out/<THEME_NAME>
```

3. theme.php
im root des Childordners eine theme.php erstellen.

```php
declare(strict_types=1);

$aTheme = [
    'id' => 'o3-shop-child',
    'title' => 'CHILD',
    'description' => 'A child theme from o3-shop.',
    'parentTheme' => 'o3-shop',
    'parentVersions' => ['1.1.0','1.3.0'],
];
```

> **Important:**
> - <THEME_NAME> = Name des benutzten Themes bei verwendung eines Child-Themes. Default o3-theme
> - <THEME_NAME> in packagist.json ändern.
> - Copy the entire `o3-theme` directory, not just its contents
> - The target should be `source/out/o3-theme/`, not `source/out/` directly

## 5. Install Build Tools


**5.1 Install Node.js & npm**

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Other Systems:**  
Download from [nodejs.org](https://nodejs.org/)

**Verify Installation:**
```bash
node --version  # Should show v22.13.0 or higher
npm --version   # Should show 10.x or higher
```

**5.2 Install Gulp CLI Globally**
```bash
npm install --global gulp-cli
```

**5.3 Install Theme Dependencies**
```bash
cd <DOCUMENT_ROOT>/source/Application/views/o3-theme/
npm install
```

@ralftrapp braucht man das unbedingt?
#### Step 4: Prepare the Database

Import the database setup (same as Composer method):

**Command Line:**
```bash
mysql -u MYSQL_USER -p SHOP_DATABASE < setup.sql
```

**Or via Shop Admin:** Service → Tools → Upload `setup.sql`

#### Step 5: Activate Theme

1. Log into Shop Admin
2. Navigate to **Extensions → Themes**
3. Find **O3 Theme** and click **Activate**

**✅ Installation complete!** You can now start developing.

---

## 3. Development

All source files for CSS and JavaScript are located in the `build/` directory.

### Available Commands

Run these commands from the theme root directory:

| Command | Description | Use Case |
|---------|-------------|----------|
| `gulp` | Production build | Minified JS/CSS (PurgeCSS standardmäßig deaktiviert) |
| `gulp dev` | Development watcher | Auto-rebuild on changes + TMP cleanup |

### Development Workflow

**Start the watcher:**
```bash
gulp dev
```

> **During development, make sure production-mode is disabled**. Only then will you be able to view the source maps and unminified assets.
>
> **💡 Tip:** Use the mode-tool, which shows you in the frontend which mode the shop is in. You can activate it in the theme settings.

The watcher monitors:
- `build/js/**/*.js` → Rebuilds JavaScript bundles
- `build/scss/**/*.scss` → Rebuilds CSS
- `tpl/**/*.html.twig` → Clears OXID TMP directory
- `Application/translations/**/*.php` → Clears OXID TMP directory

**Production build:**
```bash
gulp
```

This will:
- Minify JavaScript and CSS
- Optimize assets for production

PurgeCSS ist **standardmäßig deaktiviert**: O3-Theme ist die Basis für
Child-Themes, Module und CMS-Inhalte, die Klassen erst zur Laufzeit erzeugen.
Ein statischer Scan kann diese nicht sehen, daher würden sie im Produktivmodus
stillschweigend entfernt (im Dev-Modus fällt es nicht auf, weil dort das
ungepurged `main.css` geladen wird). Optional aktivieren:

```bash
npx gulp prod --purge    # oder: npm run build:purge — funktioniert unter Windows, macOS und Linux
```

### Optional PurgeCSS (opt-in)

Wenn PurgeCSS aktiviert wird, entfernt es ungenutzte CSS-Klassen. Dynamisch
erzeugte Klassennamen aus JavaScript oder Templates müssen dann in die
Safelist aufgenommen werden.

**Beispiel dynamischer Klassen:**
```twig
{# Template with dynamic class #}
<div class="{{ type }}-view"></div>
```

**Safelist in `gulpfile.js` ergänzen:**
```javascript
safelist: [
    'grid-view',    // Add your dynamic classes here
    'line-view',
    /^custom-/,        // Or use patterns
]
```

**Ort:** PurgeCSS-Konfiguration in `gulpfile.js` (nur bei `--purge` aktiv).

---

## 5. Asset Integration

### JavaScript
- Main JS bundle:   
  ``<DOCUMENT_ROOT>/source/Application/views/o3-theme/build/js/main.bundle.js``
- ``import`` new scripts here to include them in the **main JS**.
- Files in `build/js/widgets/` are standalone and must be explicitly loaded in templates:
  ``{{ script({ include: "js/widgets/checkagb.js", priority: 10 }) }}``
> JavaScript from modules can also be integrated into ``main.bundle.js``. Descriptions and examples can be found in the bundle-file.

### SCSS


- Main SCSS bundle:  
  ``<DOCUMENT_ROOT>/source/Application/views/o3-theme/build/scss/main.bundle.scss``
- ``@import`` new styles here to include them globally.

> CSS/SCSS from the modules can also be integrated into ``main.bundle.scss``. Descriptions and examples can be found in the bundle-file.

---

## 6. jQuery

- This theme uses Bootstrap 5.3.8, which means that vanilla JS is used instead of jQuery.
- If jQuery is absolutely necessary, enable it in theme settings (same version as theme wave).
- Deprecation warnings during build are harmless and will disappear when updating Bootstrap.


## 7. Compatibility with PayPal
The PayPal module checks the active theme ID in one of its templates:
``[{if $oViewConf->getActiveTheme()=='flow'}]`` (Smarty-Template des Moduls) 
Change ``'flow'`` to ``'o3-theme'`` for compatibility.


## 8. Issues

Please forward all issues to [https://github.com/o3-shop/o3-shop/issues](https://github.com/o3-shop/o3-shop/issues) for the project **O3 Theme**.
