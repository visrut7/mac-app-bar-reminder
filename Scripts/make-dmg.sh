#!/bin/bash
# Packages build/TwoDo.app into a distributable disk image at
# build/TwoDo.dmg — the standard "drag to Applications" installer window
# most macOS users expect from a downloaded app.
#
# Run Scripts/build-app.sh first.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="TwoDo"
APP_BUNDLE="build/${APP_NAME}.app"
DMG_PATH="build/${APP_NAME}.dmg"
STAGING_DIR="build/dmg-staging"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "error: ${APP_BUNDLE} not found — run ./Scripts/build-app.sh first" >&2
    exit 1
fi

echo "==> Staging DMG contents"
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> Creating ${DMG_PATH}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${DMG_PATH}" >/dev/null

rm -rf "${STAGING_DIR}"

echo "==> Done: ${DMG_PATH}"
echo "    Users: open the DMG, drag ${APP_NAME}.app onto Applications."
