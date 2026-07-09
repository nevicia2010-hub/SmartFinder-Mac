#!/usr/bin/env bash
set -euo pipefail

APP_NAME="SmartFinder"
VERSION="${VERSION:-0.8.32}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-local.smartfinder.app}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_BUILD_DIR="${PROJECT_ROOT}/.build/package"
APP_PATH="${PACKAGE_BUILD_DIR}/${APP_NAME}.app"
DMG_STAGE_DIR="${PACKAGE_BUILD_DIR}/dmg-root"
DIST_DIR="${OUTPUT_DIR:-${PROJECT_ROOT}/dist}"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"

cd "${PROJECT_ROOT}"

echo "Building ${APP_NAME} release binary..."
swift build -c release --product "${APP_NAME}"
BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="${BIN_DIR}/${APP_NAME}"

echo "Creating ${APP_NAME}.app..."
rm -rf "${PACKAGE_BUILD_DIR}"
mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/Resources" "${DIST_DIR}"

cp "${EXECUTABLE_PATH}" "${APP_PATH}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_PATH}/Contents/MacOS/${APP_NAME}"

sed \
    -e "s|__VERSION__|${VERSION}|g" \
    -e "s|__BUNDLE_IDENTIFIER__|${BUNDLE_IDENTIFIER}|g" \
    "${PROJECT_ROOT}/Packaging/Info.plist" > "${APP_PATH}/Contents/Info.plist"

plutil -lint "${APP_PATH}/Contents/Info.plist"

if [[ ! -f "${PROJECT_ROOT}/Packaging/AppIcon.icns" ]]; then
    echo "Packaging/AppIcon.icns is missing. Run scripts/generate_app_icon.swift first." >&2
    exit 1
fi
cp "${PROJECT_ROOT}/Packaging/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"

if [[ -d "${PROJECT_ROOT}/Sources/SmartFinder/Resources" ]]; then
    cp -R "${PROJECT_ROOT}/Sources/SmartFinder/Resources/." "${APP_PATH}/Contents/Resources/"
    find "${APP_PATH}/Contents/Resources" -name "*.strings" -print0 | while IFS= read -r -d '' strings_file; do
        plutil -lint "${strings_file}"
    done
fi

echo "Ad-hoc signing ${APP_NAME}.app..."
codesign --force --deep --sign - "${APP_PATH}"
codesign --verify --deep --strict "${APP_PATH}"

echo "Creating DMG..."
rm -rf "${DMG_STAGE_DIR}"
mkdir -p "${DMG_STAGE_DIR}"
cp -R "${APP_PATH}" "${DMG_STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGE_DIR}/Applications"

rm -f "${DMG_PATH}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"
hdiutil verify "${DMG_PATH}"

echo "App bundle: ${APP_PATH}"
echo "DMG: ${DMG_PATH}"
