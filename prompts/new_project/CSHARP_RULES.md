# C# Rules (.NET Framework / Windows Forms)

## String Constants

String constants should be centralized in static classes. Do not scatter raw strings across the codebase.

```csharp
// Config/Constants.cs
namespace MyApp.Config
{
    public static class Constants
    {
        public const string RouteLogin = "/login";
        public const string DateFormat = "yyyy-MM-dd";
        public const string AppName = "MyApplication";
    }
}
```

Usage:

```csharp
using MyApp.Config;

var route = Constants.RouteLogin;
```

---

## Localization

Use the `csharp-localization` library for multi-language support:
`D:\GIT\BenjaminKobjolke\csharp-localization`

### Installation

Add as a project reference in your `.csproj`:

```xml
<ProjectReference Include="..\csharp-localization\src\CSharpLocalization\CSharpLocalization.csproj">
  <Project>{8A7B5F1E-3D2C-4E6F-9A1B-5C8D7E2F4A3B}</Project>
  <Name>CSharpLocalization</Name>
</ProjectReference>
```

### Directory Structure

```
project/
├── lang/
│   ├── en.json         # English (default)
│   ├── de.json         # German
│   ├── languages.json  # Language metadata
│   └── ...
├── Properties/
└── Program.cs
```

### Translation File Format

Create `lang/en.json`:

```json
{
  "app": {
    "title": "My Application"
  },
  "nav": {
    "dashboard": "Dashboard",
    "settings": "Settings"
  },
  "tray": {
    "show": "Show",
    "exit": "Exit"
  },
  "common": {
    "cancel": "Cancel",
    "save": "Save"
  }
}
```

### Setup with Embedded Resources

Add language files as embedded resources in `.csproj`:

```xml
<ItemGroup>
  <EmbeddedResource Include="lang\en.json">
    <LogicalName>MyApp.lang.en.json</LogicalName>
  </EmbeddedResource>
  <EmbeddedResource Include="lang\de.json">
    <LogicalName>MyApp.lang.de.json</LogicalName>
  </EmbeddedResource>
  <EmbeddedResource Include="lang\languages.json">
    <LogicalName>MyApp.lang.languages.json</LogicalName>
  </EmbeddedResource>
</ItemGroup>
```

### Initialization

```csharp
using System.Reflection;
using CSharpLocalization;

private Localization _localization;

private void InitializeLocalization()
{
    _localization = new Localization(new LocalizationConfig
    {
        UseEmbeddedResources = true,
        ResourceAssembly = Assembly.GetExecutingAssembly(),
        ResourcePrefix = "MyApp.lang.",
        DefaultLang = null,  // null = auto-detect from system
        FallbackLang = "en"
    });
}
```

### Usage

```csharp
// Simple translation
string title = _localization.Lang("app.title");

// With placeholders
string message = _localization.Lang("messages.welcome", new Dictionary<string, string>
{
    { ":name", userName }
});

// Change language
_localization.SetLanguage("de");
```

---

## Tray Icon Setup (Theme-Aware)

Windows Forms applications with system tray icons should support both light and dark Windows themes.

### Icon Files

Example icons can be found at:
`D:\GIT\BenjaminKobjolke\claude-code\prompts\new_project\csharp_setup_files`

Required files:
- `icon_dark.ico` - Dark icon (for light Windows theme)
- `icon_light.ico` - Light icon (for dark Windows theme)

### Converting PNG to ICO

Use ImageMagick to convert PNG source files to multi-resolution ICO:

```batch
magick logo_dark.png -define icon:auto-resize=256,128,64,48,32,16 icon_dark.ico
magick logo_light.png -define icon:auto-resize=256,128,64,48,32,16 icon_light.ico
```

### Add Icons to Resources

In `Properties/Resources.resx`:

```xml
<data name="icon_dark" type="System.Resources.ResXFileRef, System.Windows.Forms">
  <value>..\data\icon_dark.ico;System.Drawing.Icon, System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a</value>
</data>
<data name="icon_light" type="System.Resources.ResXFileRef, System.Windows.Forms">
  <value>..\data\icon_light.ico;System.Drawing.Icon, System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a</value>
</data>
```

Update `Properties/Resources.Designer.cs`:

```csharp
internal static System.Drawing.Icon icon_dark {
    get {
        object obj = ResourceManager.GetObject("icon_dark", resourceCulture);
        return ((System.Drawing.Icon)(obj));
    }
}

internal static System.Drawing.Icon icon_light {
    get {
        object obj = ResourceManager.GetObject("icon_light", resourceCulture);
        return ((System.Drawing.Icon)(obj));
    }
}
```

### Theme Detection

Add Windows message constant and detection method:

```csharp
using Microsoft.Win32;

private const int WM_SETTINGCHANGE = 0x001A;

private bool IsWindowsUsingLightTheme()
{
    try
    {
        using (var key = Registry.CurrentUser.OpenSubKey(
            @"SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", false))
        {
            var value = key?.GetValue("AppsUseLightTheme");
            return value != null && (int)value == 1;
        }
    }
    catch
    {
        return true; // Default to light theme if detection fails
    }
}
```

### Dynamic Icon Switching

```csharp
private NotifyIcon _trayIcon;

private void UpdateTrayIconForTheme()
{
    bool isLightTheme = IsWindowsUsingLightTheme();
    // Light theme = light taskbar background (use dark icon)
    // Dark theme = dark taskbar background (use light icon)
    Icon iconToUse = isLightTheme
        ? Properties.Resources.icon_dark
        : Properties.Resources.icon_light;

    if (_trayIcon != null)
    {
        _trayIcon.Icon = iconToUse;
    }
}
```

### Listen for Theme Changes

Override `WndProc` to detect when Windows theme changes:

```csharp
protected override void WndProc(ref Message m)
{
    if (m.Msg == WM_SETTINGCHANGE)
    {
        UpdateTrayIconForTheme();
    }
    base.WndProc(ref m);
}
```

### Full TrayManager Example

```csharp
public class TrayManager : IDisposable
{
    private NotifyIcon _trayIcon;
    private ContextMenuStrip _contextMenu;

    public event EventHandler ShowRequested;
    public event EventHandler ExitRequested;

    public TrayManager(Icon icon, Localization localization)
    {
        CreateContextMenu(localization);
        CreateTrayIcon(icon, localization);
    }

    private void CreateContextMenu(Localization localization)
    {
        _contextMenu = new ContextMenuStrip();

        var showItem = new ToolStripMenuItem(localization.Lang("tray.show"));
        showItem.Click += (s, e) => ShowRequested?.Invoke(this, EventArgs.Empty);
        _contextMenu.Items.Add(showItem);

        _contextMenu.Items.Add(new ToolStripSeparator());

        var exitItem = new ToolStripMenuItem(localization.Lang("tray.exit"));
        exitItem.Click += (s, e) => ExitRequested?.Invoke(this, EventArgs.Empty);
        _contextMenu.Items.Add(exitItem);
    }

    private void CreateTrayIcon(Icon icon, Localization localization)
    {
        _trayIcon = new NotifyIcon
        {
            Icon = icon,
            Text = localization.Lang("app.title"),
            ContextMenuStrip = _contextMenu,
            Visible = true
        };
        _trayIcon.DoubleClick += (s, e) => ShowRequested?.Invoke(this, EventArgs.Empty);
    }

    public void UpdateIcon(Icon icon)
    {
        if (icon != null && _trayIcon != null)
        {
            _trayIcon.Icon = icon;
        }
    }

    public void Dispose()
    {
        _trayIcon?.Dispose();
        _contextMenu?.Dispose();
    }
}
```

---

## 5 Essential Additional Rules

### 1) Use a consistent project structure

```
project/
├── data/
│   ├── icon_dark.ico
│   └── icon_light.ico
├── lang/
│   ├── en.json
│   └── languages.json
├── Properties/
│   ├── AssemblyInfo.cs
│   ├── Resources.resx
│   └── Resources.Designer.cs
├── Config/
│   ├── Constants.cs
│   └── AppSettings.cs
├── Form1.cs
├── Program.cs
└── MyApp.csproj
```

---

### 2) Centralize application settings

Use a settings class with JSON persistence:

```csharp
// Config/AppSettings.cs
using System.IO;
using Newtonsoft.Json;

public class AppSettings
{
    private static readonly string SettingsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "MyApp", "settings.json");

    public static AppSettings Instance { get; } = Load();

    public string Language { get; set; } = "en";
    public bool MinimizeToTray { get; set; } = true;
    public bool LaunchOnStartup { get; set; } = false;

    private static AppSettings Load()
    {
        if (File.Exists(SettingsPath))
        {
            var json = File.ReadAllText(SettingsPath);
            return JsonConvert.DeserializeObject<AppSettings>(json) ?? new AppSettings();
        }
        return new AppSettings();
    }

    public void Save()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(SettingsPath));
        File.WriteAllText(SettingsPath, JsonConvert.SerializeObject(this, Formatting.Indented));
    }
}
```

---

### 3) Embed dependencies with Costura.Fody

For single-file distribution, embed all DLLs into the executable:

Install via NuGet:
```
Install-Package Costura.Fody
Install-Package Fody
```

Create `FodyWeavers.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Weavers xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="FodyWeavers.xsd">
  <Costura />
</Weavers>
```

---

### 4) Handle startup registration properly

For "Launch on Windows startup" functionality:

```csharp
using Microsoft.Win32;

private const string StartupRegistryKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
private const string StartupValueName = "MyApp";

private bool IsStartupEnabled()
{
    using (var key = Registry.CurrentUser.OpenSubKey(StartupRegistryKey, false))
    {
        return key?.GetValue(StartupValueName) != null;
    }
}

private void SetStartupEnabled(bool enable)
{
    using (var key = Registry.CurrentUser.OpenSubKey(StartupRegistryKey, true))
    {
        if (key == null) return;

        if (enable)
            key.SetValue(StartupValueName, Application.ExecutablePath);
        else
            key.DeleteValue(StartupValueName, false);
    }
}
```

---

### 5) Implement proper disposal pattern

All forms and managers should implement IDisposable:

```csharp
protected override void OnFormClosed(FormClosedEventArgs e)
{
    _timer?.Stop();
    _timer?.Dispose();
    _trayManager?.Dispose();
    base.OnFormClosed(e);
}
```

---

### 6) README.md is Mandatory

Every project must have a `README.md` file in the root directory. It should include:

- Project name and description
- Installation/setup instructions
- Usage examples
- Dependencies and requirements

---

### 7) Required Batch Files

Every project must include these batch files in the `tools/` directory:

- `tools/tests.bat` - Runs the test suite
- `tools/build_release.bat` - Builds the release version

---

### 8) Don't Repeat Yourself (DRY)

Avoid code duplication. If the same logic appears in multiple places, extract it into a reusable method, class, or utility.

- Duplicate code is harder to maintain and leads to bugs
- Extract shared logic into helper methods or base classes
- Use constants for repeated values (see String Constants section)

---

### 9) Confirm Dependency Versions

Before adding any new NuGet package or library, confirm the version with the user to ensure we use up-to-date dependencies.

- Do not assume which version to use
- Ask the user to verify the latest stable version
- Avoid outdated packages that may have security vulnerabilities or missing features

---

## Dark Theme UI (Optional)

For consistent dark theme in Windows Forms:

```csharp
// Colors
private static readonly Color DarkBackground = Color.FromArgb(30, 30, 30);
private static readonly Color DarkForeground = Color.White;
private static readonly Color DarkAccent = Color.FromArgb(60, 60, 60);

// Apply to form
this.BackColor = DarkBackground;
this.ForeColor = DarkForeground;

// Apply to controls
foreach (Control control in this.Controls)
{
    control.BackColor = DarkBackground;
    control.ForeColor = DarkForeground;
}
```
