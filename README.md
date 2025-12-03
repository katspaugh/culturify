# Culturify - macOS Menubar App

A minimal macOS menubar application built with Swift/SwiftUI that helps you communicate professionally and warmly on Slack using GitHub Copilot CLI or Ollama.

| Q | A |
|---|---|
| <img height="329" alt="Screenshot 2025-12-03 at 10 08 02" src="https://github.com/user-attachments/assets/a364f90e-6e52-43b6-aab0-b32aa6f3b94c" /> | <img height="329" alt="Screenshot 2025-12-03 at 10 08 16" src="https://github.com/user-attachments/assets/d348cb4f-a1b4-4438-a29a-4ca3f6e2fae0" /> |


## Features

- 🎯 Custom menubar icon
- 💬 Simple text input interface
- 🤖 GitHub Copilot CLI (Claude Haiku 4.5) with fallback to Ollama (llama3.1:8b)
- ⚡️ Fast popup UI with global keyboard shortcut (Cmd+Shift+Space)
- 📝 Auto-copy corrected text to clipboard
- ✨ Personal, warm tone - no corporate "we"

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- GitHub Copilot CLI (`gh`) OR Ollama with llama3.1:8b model

## Installation

1. Install GitHub Copilot CLI (preferred) OR Ollama:
   ```bash
   # Option 1: GitHub Copilot CLI (faster)
   gh auth login
   gh extension install github/gh-copilot
   
   # Option 2: Ollama (fallback)
   brew install ollama
   ollama pull llama3.1:8b
   ```

2. Open the project:
   ```bash
   open Culturify.xcodeproj
   ```

3. Build and run the project in Xcode (⌘R)

4. Grant Accessibility permissions for global keyboard shortcut:
   - System Settings → Privacy & Security → Accessibility
   - Add Culturify to allowed apps

## Usage

1. Press **Cmd+Shift+Space** anywhere or click the menubar icon
2. Type or paste text that needs grammar correction
3. Press **Enter** or click "Culturify" button
4. Corrected text automatically copied to clipboard
5. Press **Enter** again to start a new query

## Project Structure

- `CultureifyApp.swift` - Main app entry point
- `AppDelegate.swift` - Menubar, popover, and global hotkey management
- `ContentView.swift` - Main UI view
- `CultureifyService.swift` - Copilot CLI / Ollama integration service

## Keyboard Shortcuts

- **Cmd+Shift+Space** - Toggle popup globally
- **Enter** - Submit query / Reset after response
- **Shift+Enter** - New line in text editor

## License

MIT

## Download

Download the latest release from [GitHub Releases](https://github.com/katspaugh/culturify/releases) or [GitHub Actions](https://github.com/katspaugh/culturify/actions).

### First Launch

macOS will block the app because it's not notarized. To open it:

**Option 1: Remove quarantine attribute (recommended)**
```bash
xattr -cr Culturify.app
```

**Option 2: Allow in System Settings**
1. Right-click `Culturify.app` and select "Open"
2. Click "Open" in the security dialog
3. Or go to System Settings → Privacy & Security → Allow "Culturify"

Then move it to your Applications folder.
