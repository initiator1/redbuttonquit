#!/bin/bash
#
# RedButtonQuit Release Script
# Creates a signed, notarized DMG ready for distribution
#
# Prerequisites:
#   - Xcode installed
#   - Developer ID certificate in Keychain
#   - Notarization credentials stored in keychain profile
#
# Usage:
#   ./create-release.sh [version]
#   Example: ./create-release.sh 1.0.0

set -e

# Configuration
APP_NAME="RedButtonQuit"
BUNDLE_ID="com.redbuttonquit.app"
SCHEME="RedButtonQuit"
PROJECT="RedButtonQuit.xcodeproj"
NOTARY_PROFILE="RedButtonQuit"  # Set up with: xcrun notarytool store-credentials

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get version
VERSION=${1:-$(defaults read "$(pwd)/$APP_NAME/Supporting/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  RedButtonQuit Release Builder${NC}"
echo -e "${GREEN}  Version: $VERSION${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Directories
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build archive
echo -e "${YELLOW}Building archive...${NC}"
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    | xcpretty || xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive failed${NC}"
    exit 1
fi

# Export app
echo -e "${YELLOW}Exporting app...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist exportOptions.plist

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Export failed${NC}"
    exit 1
fi

# Verify code signature
echo -e "${YELLOW}Verifying code signature...${NC}"
codesign -dv --verbose=2 "$APP_PATH"

# Create ZIP for notarization
echo -e "${YELLOW}Creating ZIP for notarization...${NC}"
cd "$EXPORT_PATH"
zip -r "../$APP_NAME.zip" "$APP_NAME.app"
cd - > /dev/null

# Notarize
echo -e "${YELLOW}Submitting for notarization...${NC}"
echo "This may take several minutes..."

xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

# Check notarization status
echo -e "${YELLOW}Checking notarization status...${NC}"
xcrun notarytool log "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" 2>/dev/null || true

# Staple
echo -e "${YELLOW}Stapling notarization ticket...${NC}"
xcrun stapler staple "$APP_PATH"

# Verify stapling
xcrun stapler validate "$APP_PATH"

# Create DMG
echo -e "${YELLOW}Creating DMG...${NC}"

# Create staging directory
DMG_STAGING="$BUILD_DIR/dmg-staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean staging
rm -rf "$DMG_STAGING"

# Sign DMG
echo -e "${YELLOW}Signing DMG...${NC}"
codesign --force --sign "Developer ID Application" "$DMG_PATH"

# Notarize DMG
echo -e "${YELLOW}Notarizing DMG...${NC}"
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

# Staple DMG
xcrun stapler staple "$DMG_PATH"

# Calculate SHA256
echo -e "${YELLOW}Calculating SHA256...${NC}"
SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

# Final verification
echo -e "${YELLOW}Final verification...${NC}"
spctl -a -vvv "$APP_PATH" 2>&1 || true

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Release Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Version:  ${YELLOW}$VERSION${NC}"
echo -e "DMG:      ${YELLOW}$DMG_PATH${NC}"
echo -e "SHA256:   ${YELLOW}$SHA256${NC}"
echo ""
echo "Next steps:"
echo "  1. Test the DMG on a clean Mac"
echo "  2. Create GitHub release with tag v$VERSION"
echo "  3. Upload $DMG_NAME to the release"
echo "  4. Update Homebrew cask formula with SHA256: $SHA256"
echo ""

# Output for Homebrew cask update
echo "Homebrew cask formula update:"
echo "  version \"$VERSION\""
echo "  sha256 \"$SHA256\""
