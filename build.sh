#!/bin/bash
#
# Builds "TouchGuard Menu Bar.app" into build/.
#
#   ./build.sh            build
#   ./build.sh install    build, then copy to ~/Applications
#   ./build.sh package    build, then create an installer (build/TouchGuardMenuBar-<version>.pkg)
#

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD="$DIR/build"
APP="$BUILD/TouchGuard Menu Bar.app"
EXE="TouchGuardMenuBar"
PKG_ID="io.github.kimberlycoy.TouchGuardMenuBar.pkg"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$DIR/Info.plist" "$APP/Contents/Info.plist"

# Universal binary: build each architecture, then combine.
for ARCH in arm64 x86_64; do
    swiftc \
        -O \
        -swift-version 5 \
        -target "$ARCH-apple-macos13.0" \
        -parse-as-library \
        -o "$BUILD/$EXE-$ARCH" \
        "$DIR"/Sources/*.swift
done
lipo -create -output "$APP/Contents/MacOS/$EXE" "$BUILD/$EXE-arm64" "$BUILD/$EXE-x86_64"
rm -f "$BUILD/$EXE-arm64" "$BUILD/$EXE-x86_64"

# Ad-hoc signature. Note: macOS ties the Accessibility permission to the
# signature, so after each rebuild you may need to allow it again.
codesign --force --sign - "$APP"

echo "Built $APP"

if [ "${1:-}" = "install" ]; then
    mkdir -p "$HOME/Applications"
    pkill -f "TouchGuard Menu Bar.app/Contents/MacOS/$EXE" 2>/dev/null || true
    rm -rf "$HOME/Applications/TouchGuard Menu Bar.app"
    cp -R "$APP" "$HOME/Applications/"
    echo "Installed to $HOME/Applications/TouchGuard Menu Bar.app"
fi

if [ "${1:-}" = "package" ]; then
    VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$DIR/Info.plist")"
    PKG_WORK="$BUILD/pkg"
    PKG="$BUILD/TouchGuardMenuBar-$VERSION.pkg"
    rm -rf "$PKG_WORK" "$PKG"
    mkdir -p "$PKG_WORK/root"
    cp -R "$APP" "$PKG_WORK/root/"

    # Don't let Installer "relocate" the app to wherever another copy with
    # the same bundle ID lives (e.g. this build folder); always use /Applications.
    pkgbuild --analyze --root "$PKG_WORK/root" "$PKG_WORK/components.plist" > /dev/null
    /usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$PKG_WORK/components.plist"

    pkgbuild \
        --root "$PKG_WORK/root" \
        --component-plist "$PKG_WORK/components.plist" \
        --install-location /Applications \
        --identifier $PKG_ID \
        --version "$VERSION" \
        --scripts "$DIR/installer/scripts" \
        "$PKG_WORK/TouchGuardMenuBar-component.pkg" > /dev/null

    cat > "$PKG_WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>TouchGuard Menu Bar $VERSION</title>
    <welcome file="welcome.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <volume-check>
        <allowed-os-versions>
            <os-version min="13.0"/>
        </allowed-os-versions>
    </volume-check>
    <choices-outline>
        <line choice="default"/>
    </choices-outline>
    <choice id="default" title="TouchGuard Menu Bar">
        <pkg-ref id="$PKG_ID"/>
    </choice>
    <pkg-ref id="$PKG_ID" version="$VERSION">TouchGuardMenuBar-component.pkg</pkg-ref>
</installer-gui-script>
XML

    productbuild \
        --distribution "$PKG_WORK/distribution.xml" \
        --resources "$DIR/installer/resources" \
        --package-path "$PKG_WORK" \
        "$PKG" > /dev/null

    rm -rf "$PKG_WORK"
    echo "Created $PKG"
fi
