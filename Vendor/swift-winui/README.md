# swift-winui

Swift Language Bindings for common WinRT APIs and the Windows App SDK. For now, this package hosts bindings for WinUI 3, the Windows App SDK, UWP, Windows Foundation, and WebView 2 Core.

## Bindings

The bindings are generated using [thebrowsercompany/swift-winrt](https://github.com/thebrowsercompany/swift-winrt). To discover which bindings each product provides bindings for, see the `projections.json` file in the corresponding subdirectory of the `Support` directory.

## Useful resources

- [Windows App SDK API documentation](https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls?view=windows-app-sdk-1.5)
- [Official WinUI 3 GitHub repo](https://github.com/microsoft/microsoft-ui-xaml)

## SDK Versions

These bindings target a specific Windows SDK and a specific Windows App SDK. Bindings for the Windows SDK are compatible with all Windows SDK versions that follow. Bindings for Windows App SDK APIs on the other hand require that a matching Windows App Runtime version is installed.

1. Windows SDK: `10.0.17763.0`
2. Windows App SDK: `1.5-preview1`

## Depenencies

### Compiletime dependencies

To compile an app that uses swift-winui, you must install a matching version of the Windows SDK;

```pwsh
winget install --id Microsoft.WindowsSDK.10.0.17763
```

### Runtime dependencies

To run an app that uses swift-winui, you must install the correct version of the Windows App Runtime;

- x64: [windowsappruntimeinstall-x64.exe](https://aka.ms/windowsappsdk/1.5/1.5.240205001-preview1/windowsappruntimeinstall-x64.exe)
- arm64: [windowsappruntimeinstall-arm64.exe](https://aka.ms/windowsappsdk/1.5/1.5.240205001-preview1/windowsappruntimeinstall-arm64.exe)
