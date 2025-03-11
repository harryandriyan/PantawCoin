#!/bin/bash

# Exit on error
set -e

echo "Building PantawCoin.app..."

# Build the release version
swift build -c release

# Create app bundle structure
mkdir -p PantawCoin.app/Contents/{MacOS,Resources}

# Copy executable
cp .build/release/PantawCoin PantawCoin.app/Contents/MacOS/

# Create Info.plist if it doesn't exist
if [ ! -f PantawCoin.app/Contents/Info.plist ]; then
  cat > PantawCoin.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PantawCoin</string>
    <key>CFBundleIdentifier</key>
    <string>com.pantawcoin.app</string>
    <key>CFBundleName</key>
    <string>PantawCoin</string>
    <key>CFBundleDisplayName</key>
    <string>PantawCoin</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
fi

# Copy resources
mkdir -p PantawCoin.app/Contents/Resources/AppIcons
cp -r Sources/PantawCoin/Resources/AppIcons/* PantawCoin.app/Contents/Resources/AppIcons/

# Use the appstore icon as the app icon
cp Sources/PantawCoin/Resources/AppIcons/appstore.png PantawCoin.app/Contents/Resources/AppIcon.icns

echo "App bundle created at PantawCoin.app"
echo "You can run it with: open PantawCoin.app" 