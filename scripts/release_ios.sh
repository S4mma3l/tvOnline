#!/usr/bin/env bash
# Builds the iOS IPA locally and uploads it to the GitHub release.
# Usage: ./scripts/release_ios.sh v1.0.0
set -e

TAG=${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0")}
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
IPA="build/ios/ipa/tvOnline.ipa"
ARCHIVE="build/ios/archive/Runner.xcarchive"

echo "▶ Construyendo iOS IPA para $TAG..."

flutter build ipa --no-codesign --dart-define-from-file=env.json

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "build/ios/ipa" \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

echo "▶ Subiendo $IPA al release $TAG en $REPO..."

# Crea el release si no existe todavía
gh release view "$TAG" --repo "$REPO" > /dev/null 2>&1 || \
  gh release create "$TAG" --repo "$REPO" --title "tvOnline $TAG" --draft

gh release upload "$TAG" "$IPA" \
  --repo "$REPO" \
  --clobber

echo "✓ tvOnline.ipa subido al release $TAG"
echo "  https://github.com/$REPO/releases/tag/$TAG"
