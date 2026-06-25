# MacMark

A lightweight macOS markdown editor with live preview, file conversion, and QuickLook support.

## Features

- **Editor + Preview**: Split view with syntax-highlighted editor and rendered preview
- **Light & Dark Mode**: System, light, or dark — your choice
- **Export**: Save as PDF or HTML
- **File Conversion**: Convert PDF, DOCX, XLSX, CSV, JSON, HTML, XML to Markdown (native Swift, no dependencies)
- **QuickLook Extension**: Preview .md files directly in Finder
- **App Store Ready**: Sandboxed, hardened runtime, proper entitlements

## Setup

```bash
# Install XcodeGen (if needed)
brew install xcodegen

# Generate Xcode project and open
./setup.sh
```

Or manually:

```bash
xcodegen generate
open MacMark.xcodeproj
```

Then set your Development Team in **Signing & Capabilities** and hit **Cmd+R**.

## Architecture

```
MacMark/             → Main app target
├── App/             → App entry point, state management
├── Models/          → Document model (FileDocument)
├── Views/           → SwiftUI views (editor, preview, converter, settings)
└── Utilities/       → Markdown renderer, exporters, file converters, ZIP reader

MacMarkQuickLook/    → QuickLook preview extension
```

**Dependencies**: Only [swift-markdown](https://github.com/apple/swift-markdown) (Apple's own library). All file conversion is native Swift using system frameworks (PDFKit, Compression, XMLParser).

## Inspired By

File conversion inspired by [Microsoft's markitdown](https://github.com/microsoft/markitdown) — optimized for preparing documents for AI/LLM workflows.

## Requirements

- macOS 13.0+
- Xcode 15+
- Apple Silicon or Intel Mac
