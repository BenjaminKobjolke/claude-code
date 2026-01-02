# Flutter Rules (FVM + Mobile)

## Flutter Version Management

Use FVM (Flutter Version Manager) for all projects. Create `.fvmrc` in the project root:

```json
{
  "flutter": "3.24.0"
}
```

All Flutter commands should be prefixed with `fvm`:

```bash
fvm flutter pub get
fvm flutter run
fvm flutter build apk
```

---

## String Constants

String constants should be centralized in dedicated classes. Do not scatter raw strings across the codebase.

```dart
// lib/config/constants.dart
class Constants {
  Constants._();

  static const String routeLogin = '/login';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String appName = 'MyApp';
}
```

Usage:

```dart
import 'package:myapp/config/constants.dart';

final route = Constants.routeLogin;
```

---

## Localization

Use the `flutter_i18n_translations` library for multi-language support:
`D:\GIT\BenjaminKobjolke\android\flutter-i18n-translations`

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_i18n_translations:
    path: D:/GIT/BenjaminKobjolke/android/flutter-i18n-translations
```

Then run:

```bash
fvm flutter pub get
```

### Directory Structure

```
project/
├── assets/
│   └── i18n/
│       ├── en.json         # English (default)
│       ├── de.json         # German
│       └── languages.json  # Language metadata
├── lib/
│   ├── config/
│   │   ├── constants.dart
│   │   └── translation_keys.dart
│   └── main.dart
└── pubspec.yaml
```

### Configure Assets

In `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/
```

### Translation File Format

Create `assets/i18n/en.json`:

```json
{
  "app": {
    "name": "My Application",
    "welcome": "Welcome, {name}!"
  },
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
  "common": {
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "edit": "Edit"
  }
}
```

Create `assets/i18n/languages.json`:

```json
{
  "en": "English",
  "de": "Deutsch"
}
```

### Initialization

In `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_i18n_translations/flutter_i18n_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization
  final localizationService = LocalizationService();
  final languageCode = await determineSystemLanguage();
  await localizationService.load(languageCode);
  AppLocalizations.init(localizationService);

  runApp(const MyApp());
}
```

### Usage in Widgets

```dart
import 'package:flutter_i18n_translations/flutter_i18n_translations.dart';
import 'package:myapp/config/translation_keys.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple translation
        Text(AppLocalizations.tr(TK.appName)),

        // With parameters
        Text(AppLocalizations.tr(TK.appWelcome,
          params: {'name': 'John'}
        )),

        // Get current language
        Text('Current: ${AppLocalizations.currentLanguage}'),
      ],
    );
  }
}
```

---

## Translation Key Naming Convention

Use dot notation with logical grouping:

```
section.subsection.key

app.name               - Application info
nav.dashboard          - Navigation items
auth.login_title       - Authentication related
auth.error.auth_failed - Nested error messages
common.save            - Reusable UI elements
```

---

## Translation Keys as Constants

Using raw strings like `AppLocalizations.tr('nav.dashboard')` is error-prone. Create a `TK` class with all keys as constants for IDE autocomplete and compile-time checking.

Create `lib/config/translation_keys.dart`:

```dart
// lib/config/translation_keys.dart
class TK {
  TK._();

  // App
  static const String appName = 'app.name';
  static const String appWelcome = 'app.welcome';

  // Navigation
  static const String navDashboard = 'nav.dashboard';
  static const String navSettings = 'nav.settings';
  static const String navLogout = 'nav.logout';

  // Auth
  static const String authLoginTitle = 'auth.login_title';
  static const String authSigninSubtitle = 'auth.signin_subtitle';
  static const String authErrorAuthFailed = 'auth.error.auth_failed';
  static const String authErrorRateLimited = 'auth.error.rate_limited';

  // Common
  static const String commonCancel = 'common.cancel';
  static const String commonSave = 'common.save';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
}
```

Usage:

```dart
import 'package:myapp/config/translation_keys.dart';

// Instead of:
AppLocalizations.tr('nav.dashboard');

// Use:
AppLocalizations.tr(TK.navDashboard);
```

### Benefits

- IDE autocomplete for all translation keys
- Compile-time error if constant doesn't exist
- Easy to find all usages of a key
- Refactoring support

---

## Language Switching

```dart
// Get available languages
final languages = AppLocalizations.getAvailableLanguages(); // ['de', 'en']

// Get language display name
final displayName = AppLocalizations.getLanguageName('de'); // "Deutsch"

// Switch language
await localizationService.load('de');
// Rebuild UI (e.g., restart app or use state management)
```

### Persisting Language Choice

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> changeLanguage(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
  await localizationService.load(languageCode);
}

// On app start
final prefs = await SharedPreferences.getInstance();
final savedLanguage = prefs.getString('language');
final languageCode = savedLanguage ?? await determineSystemLanguage();
```

---

## Adding New Languages

1. Copy `assets/i18n/en.json` to `assets/i18n/de.json`
2. Translate all values (keep keys identical)
3. Update `assets/i18n/languages.json`:

```json
{
  "en": "English",
  "de": "Deutsch"
}
```

---

## Project Structure

Standard Flutter mobile project structure:

```
project/
├── android/                    # Android platform files
├── ios/                        # iOS platform files
├── assets/
│   ├── i18n/                   # Translation files
│   └── images/                 # Image assets
├── lib/
│   ├── config/
│   │   ├── constants.dart      # App constants
│   │   └── translation_keys.dart
│   ├── models/                 # Data models
│   ├── services/               # Business logic / API
│   ├── screens/                # Full-screen widgets
│   ├── widgets/                # Reusable widgets
│   └── main.dart
├── test/                       # Unit and widget tests
├── tools/                      # Build scripts
│   ├── tests.bat
│   ├── build_debug.bat
│   └── build_release.bat
├── .fvmrc                      # FVM Flutter version
├── pubspec.yaml
├── install.bat
├── update.bat
└── README.md
```

---

## Project Setup Scripts

Copy the setup batch files from:
`D:\GIT\BenjaminKobjolke\claude-code\prompts\new_project\flutter_setup_files`

### install.bat

Initial project setup:

- Checks if FVM is installed
- Runs `fvm install` to install Flutter version
- Runs `fvm flutter pub get` to install dependencies
- Runs tests to verify setup

### update.bat

Update all dependencies:

- Updates dependencies with `fvm flutter pub upgrade`
- Runs `fvm flutter analyze` for linting
- Runs tests to verify compatibility

### tools/tests.bat

Run the test suite:

- Runs `fvm flutter test`
- Shows pass/fail summary

### tools/build_debug.bat

Build debug APK:

- Runs `fvm flutter build apk --debug`
- Shows output location

### tools/build_release.bat

Build release APK:

- Runs `fvm flutter build apk --release`
- Shows output location

### Usage

```bash
# First time setup
install.bat

# Run tests
tools\tests.bat

# Build debug APK
tools\build_debug.bat

# Build release APK
tools\build_release.bat

# Update dependencies
update.bat
```

---

# Essential Rules

## 1) Use `pubspec.yaml` as the single source of truth

Keep all dependencies and configuration in `pubspec.yaml`.

Recommended baseline:

- Flutter/Dart SDK version constraints
- Dependencies managed via `fvm flutter pub add ...`
- Lock file committed: `pubspec.lock`

---

## 2) Enforce linting and formatting

Use the standard Flutter analyzer:

```bash
fvm flutter analyze
fvm dart format lib/
```

Configure `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
```

---

## 3) Centralize configuration

No "magic values" in code. Use a config class:

```dart
// lib/config/app_config.dart
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const bool debugMode = true;
}
```

---

## 4) Tests are mandatory

Use Flutter test framework:

```bash
fvm flutter test
```

Rules:

- Unit tests for services and business logic
- Widget tests for UI components
- No network in unit tests (use mocks)
- Run tests in CI on every push

---

## 5) README.md is Mandatory

Every project must have a `README.md` file in the root directory. It should include:

- Project name and description
- Installation/setup instructions (including FVM)
- Usage examples
- Dependencies and requirements

---

## 6) Required Batch Files

Every project must include these batch files:

- `install.bat` - In the root directory, initial project setup
- `update.bat` - In the root directory, update dependencies
- `tools/tests.bat` - Runs the test suite
- `tools/build_debug.bat` - Builds debug APK
- `tools/build_release.bat` - Builds release APK

---

## 7) Don't Repeat Yourself (DRY)

Avoid code duplication. If the same logic appears in multiple places, extract it into a reusable function, class, or widget.

- Duplicate code is harder to maintain and leads to bugs
- Extract shared logic into helper methods or base classes
- Use constants for repeated values (see String Constants section)
- Create reusable widgets for common UI patterns

---

## 8) Confirm Dependency Versions

Before adding any new package, confirm the version with the user to ensure we use up-to-date dependencies.

- Do not assume which version to use
- Ask the user to verify the latest stable version
- Avoid outdated packages that may have security vulnerabilities or missing features
- Check pub.dev for latest versions

---

## 9) State Management

For complex apps, use a state management solution. Recommended options:

- **Provider**: Simple, built into Flutter ecosystem
- **Riverpod**: Type-safe, testable, improved Provider
- **BLoC**: For complex business logic separation

Choose based on project complexity and discuss with the user.
