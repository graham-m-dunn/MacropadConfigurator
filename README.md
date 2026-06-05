# MacropadConfigurator

A native, lightweight macOS application built with SwiftUI to configure programmable WCH CH57x-based mechanical macro keyboards (including standard 3-key macro pads). 

This tool communicates directly with the macro pad using Apple's native `IOHIDManager` API. **No kernel extensions, custom drivers, or Zadig installations are required.**

---

## Features

- **Keystroke Customization**: Map physical keys to keyboard scancodes + custom modifiers (e.g. `Ctrl + C`, `Cmd + Shift + 4`).
- **Media Keys**: Assign media macros (Play/Pause, Stop, Next/Prev Track, Volume Up/Down, Calculator, Screen Lock).
- **Mouse Simulation**: Bind physical buttons or knobs to mouse buttons, cursor movements, drags, or scroll wheel deltas.
- **Onboard LED Backlight Control**: Custom configurations for LED Modes (Off, Backlight, Shock, Shock 2, Press) and colors (Red, Orange, Yellow, Green, Cyan, Blue, Purple, White).
- **Smart Hardware Identification**: Detects connected devices automatically. Disables Layer 2–4 controls on wired-only macro pads (like the 0x8851) while supporting multi-layer configurations on wireless/Bluetooth models.
- **Transmission Logging**: Real-time status display and logging of configurations written to the device memory.

---

## Supported Devices

Recognizes macro pads using the WCH CH57x microcontroller family matching:
- **Vendor IDs**: `0x1189` and `0x514C`
- **Product IDs**: `0x8840`, `0x8842`, `0x8850`, `0x8851`, and `0x8890`

---

## Installation & macOS Gatekeeper Bypass

Because this application is distributed as a compiled, unsigned binary, macOS Gatekeeper will block it on first launch with a warning like: 
* *"MacropadConfigurator" is damaged and can't be opened.* or
* *"MacropadConfigurator" cannot be opened because the developer cannot be verified.*

To run the application, follow these simple steps:

### Option A: The Right-Click Method (easiest)
1. Download the release `.zip` and extract `MacropadConfigurator.app`.
2. Drag the app into your `/Applications` folder.
3. Instead of double-clicking it, **Right-Click** (or `Control` + Click) the app icon and select **Open**.
4. A warning dialog will appear, but it will feature an **Open** button. Click **Open**.
5. macOS will remember this exception, and the app will launch normally going forward.

### Option B: Terminal Bypass (most reliable)
If macOS refuses to open the app, clear the quarantine flag manually:
1. Move the extracted `MacropadConfigurator.app` to your `/Applications` folder.
2. Open **Terminal** (`/Applications/Utilities/Terminal.app`) and run:
   ```bash
   xattr -cr /Applications/MacropadConfigurator.app
   ```
This recursively strips the quarantine attributes, allowing it to open instantly.

---

## Local Development & Compilation

To build or modify this tool locally:

1. Clone the repository.
2. Open [Package.swift](Package.swift) directly in **Xcode 14+** to manage and build the SwiftUI target.
3. Or compile it from your command line using Swift Package Manager:
   ```bash
   swift build
   ```

### Packaging an App Bundle
To package the compiled executable into a double-clickable macOS app bundle (`.app`) and zip it for release, run:
```bash
./package.sh
```
This generates `MacropadConfigurator-macOS.zip` in the root folder.

---

## Acknowledgments
Protocol layouts and commands were reverse-engineered and cross-referenced with the open-source community work in `ch57x-keyboard-tool`.
