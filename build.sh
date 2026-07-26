#!/bin/zsh
# Builds Culturify.app from main.swift. No Xcode project needed.
set -e
cd "$(dirname "$0")"

# No macro plugin flags: the Generable conformance in main.swift is written
# out by hand, because the @Generable macro plugin only ships inside Xcode.app
# and this builds with the Command Line Tools.
swiftc -O main.swift -o Culturify

APP=Culturify.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mv Culturify "$APP/Contents/MacOS/Culturify"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Culturify</string>
    <key>CFBundleIdentifier</key>
    <string>com.ivankaliaev.culturify</string>
    <key>CFBundleName</key>
    <string>Culturify</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

codesign --force --sign - "$APP"
echo "Built $APP — launch with: open $APP"
