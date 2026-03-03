# Opah

A Flutter app by Fresh Fish Digital.

## Getting started

1. **Flutter**: Ensure [Flutter](https://docs.flutter.dev/get-started/install) is installed and on your `PATH`.
2. **Xcode (macOS/iOS)**: If you're on macOS and see Xcode license errors, run:
   ```bash
   sudo xcodebuild -license
   ```
3. **Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run**:
   ```bash
   flutter run
   ```

## Building for iPhone (iOS Simulator)

If you see **"Failed to codesign ... Flutter.framework with identity -"** when building for the simulator, it’s usually because the project path contains **spaces** (e.g. `Mobile Documents`, `Fresh Fish Digital`). Xcode/Flutter scripts don’t handle those paths correctly.

**Fix: work from a path without spaces.**

1. Create a folder and copy the project there (use a path with **no spaces**):

   ```bash
   mkdir -p ~/Projects
   cp -R "/Users/julio/Library/Mobile Documents/com~apple~CloudDocs/Fresh Fish Digital/Opah" ~/Projects/Opah
   cd ~/Projects/Opah
   ```

2. Run from the new location:

   ```bash
   flutter clean && flutter pub get
   flutter run
   ```

   Choose the **iPhone** simulator when prompted.

To keep using iCloud for backup, you can sync `~/Projects/Opah` with your cloud or copy changes back when you’re done; the important part is building from a path without spaces.

## Project structure

- `lib/main.dart` – App entry point and main UI
- `test/` – Widget and unit tests

For more on Flutter, see the [documentation](https://docs.flutter.dev/).
