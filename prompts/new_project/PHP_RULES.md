# PHP Rules

## PHP Version

Use PHP 8.4 for all projects. Set the requirement in `composer.json`:

```json
{
    "require": {
        "php": "^8.4"
    }
}
```

---

## String Constants

STRING defines should be in separate classes.
Do not use them directly across all PHP classes.

```php
// Good - centralized constants
final class Constants
{
    public const ROUTE_LOGIN = '/login';
    public const FORMAT_DATE = 'Y-m-d';
}

// Usage
$route = Constants::ROUTE_LOGIN;
```

## Template Engine

Keep PHP, HTML, CSS, and JS separated.
This means using a template engine.

Use Twig 3:
```bash
composer require twig/twig
```

Do not put JS code into templates. Use separate `.js` files.

## Localization

Use the php-localization library for multi-language support:
https://github.com/BenjaminKobjolke/php-localization.git

### Installation

Add to `composer.json`:
```json
{
    "repositories": [
        {
            "type": "path",
            "url": "D:/GIT/BenjaminKobjolke/php-localization"
        }
    ],
    "require": {
        "xida/php-localization": "*"
    }
}
```

Then run:
```bash
composer update xida/php-localization
```

### Directory Structure

```
project/
├── lang/
│   ├── en.json    # English (default)
│   ├── de.json    # German
│   └── fr.json    # French
├── src/
└── templates/
```

### Translation File Format

Create `lang/en.json` with nested structure:
```json
{
    "nav": {
        "dashboard": "Dashboard",
        "settings": "Settings",
        "logout": "Logout"
    },
    "auth": {
        "login_title": "Login",
        "signin_subtitle": "Sign in to access your dashboard",
        "error": {
            "auth_failed": "Authentication failed. Please try again.",
            "rate_limited": "Too many attempts. Please try again later."
        }
    },
    "flash": {
        "success": {
            "saved": "Changes saved successfully.",
            "deleted": "Item deleted successfully."
        },
        "error": {
            "not_found": "Item not found.",
            "invalid_id": "Invalid ID."
        }
    },
    "common": {
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "edit": "Edit"
    }
}
```

### PHP Setup

#### Container Integration

Add a method to your DI Container:
```php
use PhpLocalization\Localization;

class Container
{
    private ?Localization $localization = null;

    public function getLocalization(): Localization
    {
        if ($this->localization === null) {
            $this->localization = new Localization([
                'driver' => 'json',
                'langDir' => $this->baseDir . '/lang/',  // trailing slash required
                'defaultLang' => 'en',
                'fallBackLang' => 'en',
            ]);
        }
        return $this->localization;
    }
}
```

#### Controller Helper

Add translation helper to your base controller:
```php
use PhpLocalization\Localization;

abstract class AbstractController
{
    protected function getLocalization(): Localization
    {
        return $this->container->getLocalization();
    }

    protected function t(string $key, array $params = []): string
    {
        return $this->getLocalization()->lang($key, $params);
    }
}
```

Usage in controllers:
```php
// Simple translation
$this->addFlash('success', $this->t('flash.success.saved'));

// With placeholders
$this->addFlash('info', $this->t('messages.welcome', [':name' => $user->name]));
```

### Twig Integration

#### Add the `t()` Function

In your TwigFactory or wherever you configure Twig:
```php
use Twig\TwigFunction;
use PhpLocalization\Localization;

public function create(Localization $localization): Environment
{
    $twig = new Environment($loader, [...]);

    // Add translation function
    $twig->addFunction(new TwigFunction('t', function (string $key, array $params = []) use ($localization) {
        return $localization->lang($key, $params);
    }));

    return $twig;
}
```

#### Usage in Templates

Simple translations:
```twig
<h1>{{ t('nav.dashboard') }}</h1>
<button>{{ t('common.save') }}</button>
<a href="/logout">{{ t('nav.logout') }}</a>
```

With placeholders (define in JSON as `:placeholder`):
```json
{
    "messages": {
        "welcome": "Hello, :name!",
        "items_count": "You have :count items"
    }
}
```

```twig
<p>{{ t('messages.welcome', {':name': user.name}) }}</p>
<p>{{ t('messages.items_count', {':count': items|length}) }}</p>
```

Conditional content:
```twig
{% if error == 'auth_failed' %}
    {{ t('auth.error.auth_failed') }}
{% elseif error == 'rate_limited' %}
    {{ t('auth.error.rate_limited') }}
{% endif %}
```

In attributes:
```twig
<a href="/back" title="{{ t('common.back') }}">
    <i class="icon-back"></i>
</a>

<button onclick="return confirm('{{ t('confirm.delete') }}')">
    {{ t('common.delete') }}
</button>
```

### Translation Key Naming Convention

Use dot notation with logical grouping:
```
section.subsection.key

nav.dashboard          - Navigation items
auth.login_title       - Authentication related
flash.success.saved    - Flash messages by type
flash.error.not_found
form.label.name        - Form labels
form.placeholder.email - Form placeholders
form.validation.required - Validation messages
common.save            - Reusable UI elements
errors.404.title       - Error pages
```

### Translation Keys as Constants

Using raw strings like `t('nav.dashboard')` is error-prone. Create a `TranslationKeys` class with all keys as constants for IDE autocomplete and compile-time error checking.

#### Create `src/Config/TranslationKeys.php`

```php
<?php

namespace App\Config;

final class TranslationKeys
{
    // Navigation
    public const NAV_DASHBOARD = 'nav.dashboard';
    public const NAV_SETTINGS = 'nav.settings';
    public const NAV_LOGOUT = 'nav.logout';

    // Auth
    public const AUTH_LOGIN_TITLE = 'auth.login_title';
    public const AUTH_ERROR_AUTH_FAILED = 'auth.error.auth_failed';

    // Flash messages
    public const FLASH_SUCCESS_SAVED = 'flash.success.saved';
    public const FLASH_ERROR_NOT_FOUND = 'flash.error.not_found';

    // Common
    public const COMMON_CANCEL = 'common.cancel';
    public const COMMON_SAVE = 'common.save';
}
```

#### Add as Twig Global

In TwigFactory, add TranslationKeys as a global:
```php
use App\Config\TranslationKeys;

$twig->addGlobal('TK', new TranslationKeys());
```

#### Usage in Controllers

```php
use App\Config\TranslationKeys as TK;

// Instead of:
$this->addFlash('success', $this->t('flash.success.saved'));

// Use:
$this->addFlash('success', $this->t(TK::FLASH_SUCCESS_SAVED));
```

#### Usage in Templates

```twig
{# Instead of: #}
{{ t('nav.dashboard') }}

{# Use: #}
{{ t(TK.NAV_DASHBOARD) }}
```

#### Benefits

- IDE autocomplete for all translation keys
- Compile-time error if constant doesn't exist
- Easy to find all usages of a key
- Refactoring support

### Adding New Languages

1. Copy `lang/en.json` to `lang/de.json`
2. Translate all values (keep keys identical)
3. Change language in configuration:

```php
$this->localization = new Localization([
    'driver' => 'json',
    'langDir' => $this->baseDir . '/lang/',
    'defaultLang' => 'de',  // Changed to German
    'fallBackLang' => 'en', // Falls back to English if key missing
]);
```

### Reference

Full documentation: D:\GIT\BenjaminKobjolke\php-localization\README.md

---

## Essential Rules

### README.md is Mandatory

Every project must have a `README.md` file in the root directory. It should include:

- Project name and description
- Installation/setup instructions
- Usage examples
- Dependencies and requirements

---

### Required Batch Files

Every project must include:

- `tools/tests.bat` - Runs the test suite

---

### Don't Repeat Yourself (DRY)

Avoid code duplication. If the same logic appears in multiple places, extract it into a reusable function, class, or trait.

- Duplicate code is harder to maintain and leads to bugs
- Extract shared logic into helper methods or base classes
- Use constants for repeated values (see String Constants section)

---

### Confirm Dependency Versions

Before adding any new Composer package or library, confirm the version with the user to ensure we use up-to-date dependencies.

- Do not assume which version to use
- Ask the user to verify the latest stable version
- Avoid outdated packages that may have security vulnerabilities or missing features

---

### Configuration Files

Use plain PHP config files instead of `.env` files. Do not use `vlucas/phpdotenv`.

#### Structure

```
project/
├── config/
│   ├── app.php           # General application settings (gitignored)
│   ├── app.php.example   # Template for app.php
│   ├── database.php      # Database connection settings (gitignored)
│   └── database.php.example  # Template for database.php
```

#### config/app.php.example

```php
<?php

declare(strict_types=1);

return [
    'jwt_secret' => 'your-secret-key-change-in-production',
    'jwt_lifetime' => 86400,
    'debug' => true,
];
```

#### config/database.php.example

```php
<?php

declare(strict_types=1);

use Cycle\Database\Config;

$dbHost = 'localhost';
$dbPort = 3306;
$dbName = 'your_database';
$dbUser = 'root';
$dbPass = '';

return new Config\DatabaseConfig([
    'default' => 'default',
    'databases' => [
        'default' => ['connection' => 'mysql'],
    ],
    'connections' => [
        'mysql' => new Config\MySQLDriverConfig(
            connection: new Config\MySQL\TcpConnectionConfig(
                database: $dbName,
                host: $dbHost,
                port: $dbPort,
                user: $dbUser,
                password: $dbPass,
            ),
            queryCache: true,
        ),
    ],
]);
```

#### Usage in Code

```php
// Load app config
$config = require __DIR__ . '/../config/app.php';
$jwtSecret = $config['jwt_secret'];

// Load database config (returns DatabaseConfig object)
$dbConfig = require __DIR__ . '/../config/database.php';
```

#### .gitignore

Always exclude the actual config files, only commit the examples:

```
config/app.php
config/database.php
```

#### Setup Instructions (for README.md)

```bash
cp config/app.php.example config/app.php
cp config/database.php.example config/database.php
# Edit both files with your credentials
```

---

## Database Timezone Handling

When storing DATE type fields in a database using an ORM (Cycle, Doctrine, Eloquent), be careful with timezone handling. Creating a `DateTimeImmutable` from a date string without an explicit timezone can cause dates to shift by one day.

### The Problem

```php
// Server timezone: Europe/Paris (UTC+1)
$day = new DateTimeImmutable('2026-01-15');
// Creates: 2026-01-15 00:00:00+01:00

// When ORM stores as DATE type, it may convert to UTC:
// 2026-01-15 00:00:00+01:00 → 2026-01-14 23:00:00 UTC
// DATE becomes: 2026-01-14 (one day earlier!)
```

### The Solution

Always use explicit UTC timezone with noon time for DATE fields:

```php
$day = DateTimeImmutable::createFromFormat(
    'Y-m-d H:i:s',
    $dateString . ' 12:00:00',
    new \DateTimeZone('UTC')
);
```

### Why Noon?

Using noon (12:00) instead of midnight provides a safety buffer:
- Noon UTC is within the same calendar day for all timezones (UTC-12 to UTC+14)
- No timezone conversion can shift noon to a different day
- Makes code resilient to any server timezone configuration

### When This Pattern is Needed

- **DATE type columns**: Any field that stores only a date without time
- **User-provided date strings**: When parsing `Y-m-d` format from API requests
- **Date comparisons in queries**: Ensure consistent date handling

### When This Pattern is NOT Needed

- **DATETIME/TIMESTAMP columns**: These store full timestamps with timezone info
- **"Now" calculations**: `new DateTimeImmutable()` for current time is fine
- **Timestamps** (`created_at`, `updated_at`): These are meant to store exact moments

### Testing

Always include unit tests that verify date handling across different timezones:

```php
public function testDatePreservedAcrossTimezones(): void
{
    $inputDate = '2026-01-15';
    $originalTz = date_default_timezone_get();

    foreach (['UTC', 'Europe/Paris', 'America/New_York'] as $tz) {
        date_default_timezone_set($tz);

        $day = DateTimeImmutable::createFromFormat(
            'Y-m-d H:i:s',
            $inputDate . ' 12:00:00',
            new \DateTimeZone('UTC')
        );

        $this->assertSame($inputDate, $day->format('Y-m-d'));
    }

    date_default_timezone_set($originalTz);
}
```
