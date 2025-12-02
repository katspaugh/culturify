# Ollama UI - macOS Menubar App

A minimal macOS menubar application built with Swift/SwiftUI that provides quick access to Ollama AI models.

## Features

- 🎯 Custom menubar icon
- 💬 Simple text input interface
- 🤖 Integration with Ollama (llama3.1:8b model)
- ⚡️ Fast popup UI
- 📝 Response display with reset functionality

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Ollama installed with llama3.1:8b model

## Installation

1. Make sure Ollama is installed:
   ```bash
   brew install ollama
   ollama pull llama3.1:8b
   ```

2. Open the project:
   ```bash
   open OllamaUI.xcodeproj
   ```

3. Build and run the project in Xcode (⌘R)

## Usage

1. Click the menubar icon to open the popup
2. Enter your prompt in the text area
3. Click "Submit" to send to Ollama
4. View the response
5. Click the refresh icon to start a new query

## Project Structure

- `OllamaUIApp.swift` - Main app entry point
- `AppDelegate.swift` - Menubar and popover management
- `ContentView.swift` - Main UI view
- `OllamaService.swift` - Ollama integration service

## License

MIT
