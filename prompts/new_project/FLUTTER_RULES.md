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
│   │   ├── app_config.dart     # API URLs, timeouts
│   │   ├── constants.dart      # App constants
│   │   └── translation_keys.dart
│   ├── models/                 # Data models & ObjectBox entities
│   ├── repositories/           # Data access (ObjectBox CRUD)
│   ├── services/
│   │   ├── api_client.dart     # Dio HTTP client singleton
│   │   └── objectbox_service.dart  # ObjectBox initialization
│   ├── screens/                # Full-screen widgets
│   ├── widgets/                # Reusable widgets
│   ├── objectbox.g.dart        # Generated ObjectBox code
│   ├── objectbox-model.json    # Generated ObjectBox model
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

### Standard Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Localization
  flutter_i18n_translations:
    path: D:/GIT/BenjaminKobjolke/android/flutter-i18n-translations

  # HTTP
  dio: ^5.9.0

  # Database
  objectbox: ^5.1.0

  # Utilities
  path_provider: ^2.1.0
  path: ^1.9.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # ObjectBox code generation
  objectbox_generator: ^5.1.0
  build_runner: ^2.4.0
```

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

## 9) State Management (Cubit)

Use **Cubit** from the `flutter_bloc` package for state management. Cubit is the recommended approach for all Flutter projects.

### Why Cubit?

- **Simpler than BLoC**: No events, just methods that emit states
- **Predictable**: Clear separation between UI and business logic
- **Testable**: Easy to unit test state changes
- **Scalable**: Works for simple screens and complex apps alike
- **Less boilerplate**: Compared to full BLoC pattern

### Installation

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5  # For state comparison
```

```bash
fvm flutter pub get
```

### Basic Example

**State class** (`lib/cubits/counter_state.dart`):

```dart
import 'package:equatable/equatable.dart';

class CounterState extends Equatable {
  final int count;
  final bool isLoading;

  const CounterState({
    this.count = 0,
    this.isLoading = false,
  });

  CounterState copyWith({int? count, bool? isLoading}) {
    return CounterState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [count, isLoading];
}
```

**Cubit class** (`lib/cubits/counter_cubit.dart`):

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_state.dart';

class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(const CounterState());

  void increment() {
    emit(state.copyWith(count: state.count + 1));
  }

  void decrement() {
    emit(state.copyWith(count: state.count - 1));
  }

  Future<void> loadFromApi() async {
    emit(state.copyWith(isLoading: true));
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    emit(state.copyWith(count: 42, isLoading: false));
  }
}
```

**Usage in Widget**:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/counter_cubit.dart';
import '../cubits/counter_state.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const CounterView(),
    );
  }
}

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: BlocBuilder<CounterCubit, CounterState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Text('Count: ${state.count}'),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => context.read<CounterCubit>().increment(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => context.read<CounterCubit>().decrement(),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```

### Project Structure

```
lib/
├── cubits/
│   ├── counter_cubit.dart
│   ├── counter_state.dart
│   ├── auth_cubit.dart
│   └── auth_state.dart
├── screens/
│   └── counter_screen.dart
└── main.dart
```

### Key Patterns

- **One Cubit per feature/screen**: Keep cubits focused
- **Immutable states**: Always use `copyWith` pattern
- **Equatable**: Use for efficient state comparison
- **BlocProvider**: Provide cubits at the widget level
- **BlocBuilder**: Rebuild UI when state changes
- **BlocListener**: Handle side effects (navigation, snackbars)

---

## 10) HTTP Communication (Dio)

Use Dio for all HTTP communication.

### Installation

```bash
fvm flutter pub add dio
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.9.0
```

### API Client Singleton

Create `lib/services/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:myapp/config/app_config.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.requestTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static Dio get instance => _dio;
}
```

### Usage Example

```dart
import 'package:myapp/services/api_client.dart';

class UserService {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getUser(int id) async {
    final response = await _dio.get('/users/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/users', data: data);
    return response.data;
  }
}
```

### Error Handling

```dart
import 'package:dio/dio.dart';

Future<void> fetchData() async {
  try {
    final response = await ApiClient.instance.get('/data');
    // Handle success
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        // Handle timeout
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        // Handle HTTP errors (400, 401, 404, 500, etc.)
        break;
      case DioExceptionType.connectionError:
        // Handle no internet
        break;
      default:
        // Handle other errors
        break;
    }
  }
}
```

---

## 11) Database (ObjectBox)

Use ObjectBox for local persistence.

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  objectbox: ^5.1.0

dev_dependencies:
  objectbox_generator: ^5.1.0
  build_runner: ^2.4.0
```

Run:

```bash
fvm flutter pub get
fvm dart run build_runner build
```

### Entity Example

Create `lib/models/user.dart`:

```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  @Id()
  int id = 0;

  String name;
  String email;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  User({
    this.id = 0,
    required this.name,
    required this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

### ObjectBox Initialization

Create `lib/services/objectbox_service.dart`:

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../objectbox.g.dart';

class ObjectBoxService {
  ObjectBoxService._();

  static Store? _store;

  static Store get store {
    if (_store == null) {
      throw Exception('ObjectBox not initialized. Call init() first.');
    }
    return _store!;
  }

  static Future<void> init() async {
    if (_store != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'objectbox');
    _store = await openStore(directory: dbPath);
  }

  static void close() {
    _store?.close();
    _store = null;
  }
}
```

Initialize in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ObjectBox
  await ObjectBoxService.init();

  // Initialize localization
  // ...

  runApp(const MyApp());
}
```

### Basic CRUD Operations

```dart
import 'package:myapp/models/user.dart';
import 'package:myapp/services/objectbox_service.dart';
import '../objectbox.g.dart';

class UserRepository {
  final Box<User> _box = ObjectBoxService.store.box<User>();

  // Create or Update
  int put(User user) {
    return _box.put(user);
  }

  // Get by ID
  User? get(int id) {
    return _box.get(id);
  }

  // Get all
  List<User> getAll() {
    return _box.getAll();
  }

  // Delete
  bool delete(int id) {
    return _box.remove(id);
  }

  // Query
  List<User> findByName(String name) {
    final query = _box.query(User_.name.equals(name)).build();
    final results = query.find();
    query.close();
    return results;
  }
}
```

---

## 12) In-App Debugger (Logarte)

For debugging network requests and viewing logs directly on the device, use Logarte.

See the detailed integration guide: [In-App Debugger Documentation](flutter/IN_APP_DEBUGGER.md)

**Requirements:**
- Must be accessible from the Settings screen
- Must be enable/disable via `AppConfig.enableLogarte`

**Key features:**
- Network request logging (automatic with Dio interceptor)
- Navigation event logging
- Searchable log viewer
- Password protection for release builds
- Log sharing and export
