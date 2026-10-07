# Vendor/swift-winui

[moreSwift/swift-winui](https://github.com/moreSwift/swift-winui) 0.2.2 (`c4f1cb7`), the WinRT projection
WinUIBackend draws with, with more of the Windows SDK projected for video playback:

| Projection | Added to `include` | For |
|---|---|---|
| `Support/WinUI/projections.json` | `Microsoft.UI.Xaml.Controls.MediaPlayerElement`, `Microsoft.UI.Xaml.Controls.MediaTransportControls` | `VideoPlayer` on WinUI: the platform's own video element and transport controls |
| `Support/UWP/projections.json` | `Windows.Media.Core.CodecQuery`, `Windows.Media.Core.CodecSubtypes`, `Windows.Security.Cryptography.CryptographicBuffer` | an app's decoder probe, and bytes handed to a WinRT stream as one buffer |

Upstream generates only the types a projection lists (plus what they reference), and 0.2.2 lists neither the media
element nor the codec query, although `Windows.Media.Playback` and `Windows.Media.Core` themselves are projected.
Nothing else differs from upstream: the change is the two `projections.json` files and the regenerated
`Sources/UWP/Generated` and `Sources/WinUI/Generated`. The C headers in `Sources/CWinRT` already describe the whole
SDK and are unchanged.

The package is a path dependency of this fork (`Package.swift`), so an app that uses its products too (Avelio's
Windows player uses `UWP`) refers to the same directory: `<fork>/Vendor/swift-winui`.

## Regenerating

On Windows (the generator is a Windows program, swift-winrt 0.5.0 from NuGet), from a copy of this directory:

```powershell
powershell -ExecutionPolicy Bypass -File Support\UWP\generate-bindings.ps1
powershell -ExecutionPolicy Bypass -File Support\WinUI\generate-bindings.ps1
```

Each script restores its NuGet packages (swift-winrt, the Windows SDK contracts, the Windows App SDK) into
`Support/<project>/.packages`, runs `swiftwinrt.exe` over their `.winmd` files with the projection's `include` list
and replaces `Sources/<project>/Generated`. Copy the two `Generated` folders back here; `.packages` and `.generated`
are ignored. From the Mac, the winbridge VM does the same: `winbridge/avelio-playback-gen.ps1` copies
`~/Projects/swift-winui-avelio` into the guest, runs both scripts and writes the results to
`winbridge/avelio-playback-gen/{UWP,WinUI}`.

To add a type, append its full name to the right `projections.json`, regenerate, and check that the diff of
`Generated` only adds code.
