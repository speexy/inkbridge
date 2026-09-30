# InkBridge

Unofficial macOS support for the Supernote InkFlow feature. Drives the Mac cursor with pressure and tilt from a Supernote stylus over USB, without needing the Supernote Partner app running.

Note: I am *not* a Swift programmer, this was done with AI help, but it does work! Don't judge the code _too_ harshly :) 

![InkBridge menu bar](screenshot.png)

## Use

1. Build and launch `InkBridge.app`
2. Grant Accessibility and Input Monitoring when prompted
3. Plug in the Supernote, open InkFlow on the device

## Troubleshooting

InkBridge needs exclusive access to the Supernote. The menu shows when it can't get it:

- **"Supernote in use by another app"**: another app, usually Supernote Partner, is holding the device. Quit it, then unplug and replug the Supernote.
- **"Couldn't open Supernote (error 0x…)"**: opening failed for another reason. Unplug and replug the Supernote.

In both cases InkBridge retries every 2 seconds and connects on its own once the device is free.

**Known limitation:** if the Supernote is plugged in while InkBridge is already running *and* another app holds it, the menu may show "Connected" but the pen does nothing. InkBridge can't detect this case. Quit the other app and relaunch InkBridge.

## Build

```
xcodegen generate
open InkBridge.xcodeproj
```

Requires Xcode 15+ and macOS 13+. Ad-hoc signed by default.

## Tests

```
swift test
```

Uses Swift Testing through `Package.swift`, which exists only for tests. It works with just the Command Line Tools. The app itself is still built from the Xcode project. Tests must not post real input events, so keep testable logic free of CGEvent/IOKit side effects.

## Not affiliated with Ratta / Supernote.
