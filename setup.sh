#!/bin/bash
# MacMark - Project Setup Script
# Run this to generate the Xcode project and open it.

set -e

echo "🔧 Setting up MacMark..."

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen..."
    brew install xcodegen
fi

# Generate Xcode project
echo "📐 Generating Xcode project..."
xcodegen generate

echo "✅ Project generated successfully!"
echo ""
echo "Opening in Xcode..."
open MacMark.xcodeproj

echo ""
echo "Next steps:"
echo "  1. Set your Development Team in Signing & Capabilities"
echo "  2. Build and run (Cmd+R)"
echo "  3. To distribute, archive (Product > Archive)"
