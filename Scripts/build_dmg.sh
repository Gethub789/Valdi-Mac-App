#!/bin/bash
set -e

# ==============================================================================
# Valdi Automated macOS DMG Builder & Packaging Pipeline
# Targets macOS 14.0+ (Apple Silicon & Intel Universal / Native)
# ==============================================================================

APP_NAME="Valdi"
BUNDLE_ID="com.valdi.app"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
STAGING_DIR="dist_staging"

echo "==> [1/5] Compiling Valdi release binary..."
swift build -c release

echo "==> [2/5] Creating application bundle structure..."
rm -rf "${APP_BUNDLE}"
rm -f "${DMG_NAME}" "${ZIP_NAME}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Sources/Valdi/Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Copy the SwiftPM resource bundle without flattening it so Bundle.module can find it.
RESOURCE_BUNDLE="${BUILD_DIR}/Valdi_Valdi.resources"
if [ -d "${RESOURCE_BUNDLE}" ]; then
    cp -R "${RESOURCE_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/"
    if [ -f "${RESOURCE_BUNDLE}/AppIcon.icns" ]; then
        cp "${RESOURCE_BUNDLE}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
    fi
fi

echo "==> [3/5] Ad-hoc code signing app bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> [4/5] Preparing DMG staging environment..."
rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"

cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
# Create standard symlink to /Applications for drag-and-drop installer UX
ln -s /Applications "${STAGING_DIR}/Applications"

echo "==> [5/5] Generating release disk image (DMG)..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov -format UDZO \
    "${DMG_NAME}"

# Cleanup temporary staging folder
rm -rf "${STAGING_DIR}"

# Create a ZIP containing the compiled app bundle for direct download.
zip -qr -X "${ZIP_NAME}" "${APP_BUNDLE}"

echo "======================================================================"
echo "SUCCESS: Valdi packages built successfully: ${DMG_NAME} and ${ZIP_NAME}"
echo "Execution Loop: Install from the DMG or unzip the app and move it to Applications"
echo "======================================================================"
