# RedButtonQuit Build System
#
# Usage:
#   make build        - Build release version
#   make run          - Build and run debug version
#   make archive      - Create archive for distribution
#   make notarize     - Notarize the app (requires credentials)
#   make dmg          - Create DMG for distribution
#   make clean        - Clean build artifacts

# Configuration
APP_NAME = RedButtonQuit
BUNDLE_ID = com.redbuttonquit.app
SCHEME = RedButtonQuit
PROJECT = RedButtonQuit.xcodeproj

# Paths
BUILD_DIR = build
ARCHIVE_PATH = $(BUILD_DIR)/$(APP_NAME).xcarchive
EXPORT_PATH = $(BUILD_DIR)/export
APP_PATH = $(EXPORT_PATH)/$(APP_NAME).app
DMG_PATH = $(BUILD_DIR)/$(APP_NAME).dmg
ZIP_PATH = $(BUILD_DIR)/$(APP_NAME).zip

# Signing. Two Developer ID certs share team MDWFZC6396 (Douglas Baker and INITIATOR LLC), so
# the identity must be named in full — "Developer ID Application" alone picks either one.
TEAM_ID = MDWFZC6396
SIGN_IDENTITY = Developer ID Application: INITIATOR LLC ($(TEAM_ID))

# Notarization. The keychain profile is created once by the account holder with:
#   xcrun notarytool store-credentials "RedButtonQuit" --apple-id <id> --team-id $(TEAM_ID)
NOTARY_PROFILE = RedButtonQuit

# Versioning
VERSION := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $(APP_NAME)/Supporting/Info.plist 2>/dev/null || echo "1.0.0")
BUILD_NUMBER := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleVersion" $(APP_NAME)/Supporting/Info.plist 2>/dev/null || echo "1")

.PHONY: all build debug release run install reset-permission test archive export notarize staple dmg clean help

all: build

help:
	@echo "RedButtonQuit Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make build       - Build release version"
	@echo "  make debug       - Build debug version"
	@echo "  make run         - Build and run debug version"
	@echo "  make install     - Install to /Applications (keeps Accessibility grant)"
	@echo "  make reset-permission - Clear the Accessibility grant and relaunch"
	@echo "  make test        - Run tests"
	@echo "  make archive     - Create xcarchive"
	@echo "  make export      - Export app from archive"
	@echo "  make notarize    - Notarize the app"
	@echo "  make staple      - Staple notarization ticket"
	@echo "  make dmg         - Create DMG"
	@echo "  make release     - Full release pipeline"
	@echo "  make clean       - Clean build artifacts"
	@echo ""
	@echo "Current version: $(VERSION) ($(BUILD_NUMBER))"

# Build targets
build: release

debug:
	@echo "Building $(APP_NAME) (Debug)..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=macOS' \
		build

release:
	@echo "Building $(APP_NAME) (Release)..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'platform=macOS' \
		build

run: debug
	@echo "Running $(APP_NAME)..."
	open ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)*/Build/Products/Debug/$(APP_NAME)Debug.app

# Install the release build to /Applications, keeping the Accessibility grant intact.
#
# Release is signed with the INITIATOR LLC Developer ID, so the grant is keyed to that identity
# rather than to a code hash. Rebuilds keep working without re-granting. Do not add a tccutil
# reset here — that was only needed while the app was ad-hoc signed (see KI-002).
install: release
	@echo "Installing $(APP_NAME) to /Applications..."
	@pkill -f "/Applications/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@sleep 1
	@rm -rf /Applications/$(APP_NAME).app
	@cp -R ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)-*/Build/Products/Release/$(APP_NAME).app /Applications/
	@codesign --verify --strict /Applications/$(APP_NAME).app || \
		(echo "SIGNATURE INVALID — not launching"; exit 1)
	@open /Applications/$(APP_NAME).app
	@echo "Installed. Accessibility permission carries over."

# Clear the Accessibility grant. Needed only when switching signing identity, or to recover a
# record that macOS has got into a bad state.
reset-permission:
	@tccutil reset Accessibility com.redbuttonquit.app
	@pkill -f "/Applications/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@sleep 1
	@open /Applications/$(APP_NAME).app 2>/dev/null || true
	@echo "Grant cleared. Use the menu bar item 'Grant Accessibility Permission...' to re-grant."

# Test
test:
	@echo "Running tests..."
	xcodebuild test -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=macOS'
	@# The test host touches the Accessibility API, which leaves it in the Accessibility
	@# list. Clear it so only the real app is ever listed there.
	@tccutil reset Accessibility com.redbuttonquit.app.debug >/dev/null 2>&1 || true

# Archive for distribution
archive:
	@echo "Creating archive..."
	@mkdir -p $(BUILD_DIR)
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		archive

# Export from archive
export: archive exportOptions.plist
	@echo "Exporting app..."
	xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist exportOptions.plist

# Recreate exportOptions.plist if it goes missing. Must stay in sync with the checked-in file —
# manual signing plus the full identity name, or the export picks the wrong Developer ID cert.
exportOptions.plist:
	@echo "Creating exportOptions.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $@
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $@
	@echo '<plist version="1.0">' >> $@
	@echo '<dict>' >> $@
	@echo '    <key>method</key>' >> $@
	@echo '    <string>developer-id</string>' >> $@
	@echo '    <key>destination</key>' >> $@
	@echo '    <string>export</string>' >> $@
	@echo '    <key>signingStyle</key>' >> $@
	@echo '    <string>manual</string>' >> $@
	@echo '    <key>teamID</key>' >> $@
	@echo '    <string>$(TEAM_ID)</string>' >> $@
	@echo '    <key>signingCertificate</key>' >> $@
	@echo '    <string>$(SIGN_IDENTITY)</string>' >> $@
	@echo '</dict>' >> $@
	@echo '</plist>' >> $@

# Notarization
notarize: export
	@echo "Creating ZIP for notarization..."
	@cd $(EXPORT_PATH) && zip -r ../$(APP_NAME).zip $(APP_NAME).app
	@echo "Submitting for notarization..."
	xcrun notarytool submit $(ZIP_PATH) \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@echo "Notarization complete!"

staple:
	@echo "Stapling notarization ticket..."
	xcrun stapler staple $(APP_PATH)
	@echo "Stapling complete!"

# DMG creation
dmg: staple
	@echo "Creating DMG..."
	@rm -f $(DMG_PATH)
	@mkdir -p $(BUILD_DIR)/dmg-staging
	@cp -R $(APP_PATH) $(BUILD_DIR)/dmg-staging/
	@ln -s /Applications $(BUILD_DIR)/dmg-staging/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder $(BUILD_DIR)/dmg-staging \
		-ov -format UDZO \
		$(DMG_PATH)
	@rm -rf $(BUILD_DIR)/dmg-staging
	@echo "Signing DMG..."
	codesign --force --sign "$(SIGN_IDENTITY)" --timestamp $(DMG_PATH)
	@echo "DMG created: $(DMG_PATH)"

# Full release pipeline
release-full: clean export notarize staple dmg
	@echo ""
	@echo "==================================="
	@echo "Release $(VERSION) complete!"
	@echo "==================================="
	@echo "DMG: $(DMG_PATH)"
	@echo ""
	@echo "Next steps:"
	@echo "1. Test the DMG on a clean Mac"
	@echo "2. Upload to GitHub Releases"
	@echo "3. Update Homebrew cask formula"

# Verification
verify:
	@echo "Verifying code signature..."
	codesign -dv --verbose=4 $(APP_PATH)
	@echo ""
	@echo "Verifying notarization..."
	xcrun stapler validate $(APP_PATH)
	@echo ""
	@echo "Checking Gatekeeper..."
	spctl -a -vvv $(APP_PATH)

# Clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -rf ~/Library/Developer/Xcode/DerivedData/$(APP_NAME)*
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	@echo "Clean complete!"

# Version bumping helpers
bump-patch:
	@echo "Bumping patch version..."
	@# Increment patch version (1.0.0 -> 1.0.1)
	@NEW_VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $$NEW_VERSION" $(APP_NAME)/Supporting/Info.plist; \
	echo "Version bumped to $$NEW_VERSION"

bump-minor:
	@echo "Bumping minor version..."
	@# Increment minor version (1.0.x -> 1.1.0)
	@NEW_VERSION=$$(echo $(VERSION) | awk -F. '{print $$1"."$$2+1".0"}'); \
	/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $$NEW_VERSION" $(APP_NAME)/Supporting/Info.plist; \
	echo "Version bumped to $$NEW_VERSION"

bump-major:
	@echo "Bumping major version..."
	@# Increment major version (1.x.x -> 2.0.0)
	@NEW_VERSION=$$(echo $(VERSION) | awk -F. '{print $$1+1".0.0"}'); \
	/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $$NEW_VERSION" $(APP_NAME)/Supporting/Info.plist; \
	echo "Version bumped to $$NEW_VERSION"

bump-build:
	@echo "Bumping build number..."
	@NEW_BUILD=$$(($(BUILD_NUMBER) + 1)); \
	/usr/libexec/PlistBuddy -c "Set CFBundleVersion $$NEW_BUILD" $(APP_NAME)/Supporting/Info.plist; \
	echo "Build number bumped to $$NEW_BUILD"
