# Culturify

A minimal macOS menubar app that rewrites text to be polite, warm, and
Slack-ready using Apple's on-device
[Foundation Models](https://developer.apple.com/documentation/foundationmodels)
(the ~3B-parameter Apple Intelligence model).

No Xcode project — one Swift file, built with `swiftc`. Everything runs
on-device; nothing is sent over the network.

| Q | A |
|---|---|
| <img height="329" alt="Screenshot 2025-12-03 at 10 08 02" src="https://github.com/user-attachments/assets/a364f90e-6e52-43b6-aab0-b32aa6f3b94c" /> | <img height="329" alt="Screenshot 2025-12-03 at 10 08 16" src="https://github.com/user-attachments/assets/d348cb4f-a1b4-4438-a29a-4ca3f6e2fae0" /> |

## Features

- 🎯 Lives in the menubar — no Dock icon, no windows
- ⚡️ Global keyboard shortcut (Cmd+Shift+Space) opens the popup anywhere
- 🍏 Apple's on-device Foundation model — fully offline, no API keys, no CLIs
- 📝 Rewritten text is auto-copied to the clipboard
- ✨ Personal, warm tone — no corporate "we"

## Requirements

- macOS 26 (Tahoe) on Apple silicon
- Apple Intelligence enabled in System Settings

## Build & run

```sh
./build.sh
open Culturify.app
```

## Usage

1. Press **Cmd+Shift+Space** anywhere, or click the menubar icon
2. Type or paste the text you want to soften
3. Press **Enter** (Shift+Enter for a newline)
4. The rewritten text is copied to the clipboard automatically
5. Press **Enter** again to start over

Right-click the menubar icon (or press Cmd+Q while the popup is open) to quit.

## Notes

- The model's context window is 4,096 tokens; each rewrite is stateless, so
  there's no conversation carry-over.
- The rewrite instructions live in one place — the `Culturifier` enum in
  `main.swift` — tweak the tone there.

## Download

Download the latest release from
[GitHub Releases](https://github.com/katspaugh/culturify/releases) or
[GitHub Actions](https://github.com/katspaugh/culturify/actions).

### First Launch

The app is ad-hoc signed, not notarized. If macOS blocks it:

```sh
xattr -cr Culturify.app
```

Or right-click `Culturify.app` → "Open" → "Open".

## Also in this repo

- [Nudge](Nudge/README.md) — a tiny Apple Watch app that taps your wrist
  every 20 minutes.

## License

MIT
