#!/bin/zsh
# Builds Culturify.app from main.swift. No Xcode project needed.
set -e
cd "$(dirname "$0")"

# @Generable and @Guide are compiler-plugin macros. Xcode points the compiler
# at the plugin executables for you; a bare swiftc does not, and the build
# fails with "plugin for module 'FoundationModelsMacros' not found". Pass
# every plugin directory this toolchain actually has.
plugin_flags=()
for dir in \
  "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins" \
  "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins" \
  "$(xcrun --sdk macosx --show-sdk-path)/usr/lib/swift/host/plugins"
do
  if [[ -d "$dir" ]]; then plugin_flags+=(-plugin-path "$dir"); fi
done

if [[ ${#plugin_flags} -eq 0 ]]; then
  echo "warning: no Swift macro plugin directories found; @Generable will not expand" >&2
fi

swiftc -O "${plugin_flags[@]}" main.swift -o Culturify

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
