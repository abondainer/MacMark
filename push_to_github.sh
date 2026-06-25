#!/bin/bash
# MacMark - Push to GitHub
cd "$(dirname "$0")"
set -e

# Remove stale lock if exists
rm -f .git/index.lock

# Remove test file
rm -f test_macmark.md

# Configure git identity
git config user.email "cjaramillo@distilledinnovation.co"
git config user.name "Carlos Jaramillo"

# Add all files and commit
git add -A
git commit -m "MacMark v1.0 - Native macOS Markdown editor

Features:
- Read mode with native HTML rendering (NSTextView)
- Edit mode with syntax highlighting
- Light/dark/system appearance toggle
- Tab-based document management
- Export to PDF and HTML
- Convert PDF, DOCX, XLSX, CSV, JSON, HTML, XML to Markdown
- QuickLook extension for Finder preview
- Welcome screen with recent files
- App icon (emerald green)
- App Sandbox ready"

# Add remote and push
git remote add origin https://github.com/abondainer/MacMark.git 2>/dev/null || true
git branch -M main
git push -u origin main

echo ""
echo "Done! https://github.com/abondainer/MacMark"
