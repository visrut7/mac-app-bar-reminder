#!/bin/bash
# Builds TwoDo and assembles it into a double-clickable .app bundle
# under ./build/TwoDo.app
#
# Optional: VERSION=1.2.0 ./Scripts/build-app.sh stamps that version into
# the bundle's Info.plist (used by CI when building from a git tag).
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="TwoDo"
CONFIG="release"
BUILD_DIR=".build/${CONFIG}"
APP_BUNDLE="build/${APP_NAME}.app"
VERSION="${VERSION:-1.0}"

echo "==> Building ${APP_NAME} (${CONFIG})"
swift build -c "${CONFIG}"

echo "==> Assembling ${APP_BUNDLE} (version ${VERSION})"
rm -rf "build"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
else
    echo "    (no Resources/AppIcon.icns found — run Scripts/generate-icon.swift to create one)"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP_BUNDLE}/Contents/Info.plist"

# Ad-hoc code sign so macOS treats it as a normal local app (required for
# SMAppService login-item registration to work reliably).
codesign --force --deep --sign - "${APP_BUNDLE}" >/dev/null 2>&1 || true

echo "==> Done: ${APP_BUNDLE}"
echo "    Run it with: open ${APP_BUNDLE}"
echo "    Or copy it to /Applications for 'Launch at Login' to work as expected."
